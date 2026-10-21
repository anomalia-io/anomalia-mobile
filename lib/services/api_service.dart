import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';

/// Deep link de retorno del callback OIDC (spec 020).
const String kOidcCallbackRedirect = 'anomalia://callback';

/// Deep link para preconfigurar el servidor escaneando el QR desde la web.
const String kOidcConfigDeepLink = 'anomalia://config';

class ApiService {
  /// URL del gateway configurada en runtime (spec: app multi-server). El default
  /// puede inyectarse al compilar con `--dart-define=API_BASE_URL=...`. Sin
  /// define, arranca vacía: el usuario debe configurar el servidor.
  static const String _compiledDefault = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Cliente HTTP compartido. En debug acepta el certificado autofirmado de la
  /// CA local de desarrollo; en release usa validación TLS estándar (seguro).
  static final http.Client _client = _buildClient();

  static http.Client _buildClient() {
    if (kDebugMode) {
      final io = HttpClient();
      io.badCertificateCallback = (cert, host, port) => true;
      return IOClient(io);
    }
    return http.Client();
  }

  static const String _prefsKey = 'api_base_url';

  static String _baseUrl = _compiledDefault;

  /// Base de la API usada por todas las llamadas (incluye `/api/v1`).
  static String get baseUrl => _baseUrl;

  /// Normaliza lo que ingresa el usuario a `https://host/api/v1`.
  ///
  /// Acepta con o sin esquema, con o sin `/api/v1` y con o sin barra final.
  static String normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return _compiledDefault;
    if (!url.contains('://')) url = 'https://$url';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api/v1')) url = '$url/api/v1';
    return url;
  }

  /// Carga la URL guardada (si existe) en memoria. Llamar antes de `runApp`.
  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null && stored.trim().isNotEmpty) {
      _baseUrl = normalizeBaseUrl(stored);
    } else {
      _baseUrl = _compiledDefault;
    }
  }

  /// ¿Ya hay un servidor configurado por el usuario?
  static Future<bool> hasConfiguredServer() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    return stored != null && stored.trim().isNotEmpty;
  }

  /// Persiste y activa una URL de gateway nueva.
  static Future<String> setBaseUrl(String raw) async {
    final normalized = normalizeBaseUrl(raw);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, normalized);
    _baseUrl = normalized;
    return normalized;
  }

  /// Verifica que el gateway responda. Devuelve el modo de auth si es válido.
  static Future<Map<String, dynamic>> probeServer(String raw) async {
    final normalized = normalizeBaseUrl(raw);
    final response = await _client.get(
      Uri.parse('$normalized/settings/auth'),
      headers: {"Content-Type": "application/json"},
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, dynamic>> getAuthSettings() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/settings/auth'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"auth_mode": "hybrid"};
      }
    } catch (e) {
      return {"auth_mode": "hybrid"};
    }
  }

  static Future<String> getOidcLoginUrl() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/oidc/login?session_type=mobile&redirect_uri=$kOidcCallbackRedirect'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['auth_url'] ?? data['url'] ?? '';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al obtener la URL de OIDC');
      }
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para OIDC');
    }
  }

  /// Completa el flujo OIDC móvil: el IdP redirige a `anomalia://callback` con
  /// `code`/`state`, y la app llama al backend para intercambiar por el token.
  static Future<Map<String, dynamic>> completeOidcMobile(String code, String state) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/oidc/callback?code=${Uri.encodeComponent(code)}&state=${Uri.encodeComponent(state)}'),
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Error completando OIDC');
    }
    return data;
  }

  /// Método agregado para almacenar credenciales devueltas por OIDC en SharedPreferences
  static Future<void> saveOidcTokens(String accessToken, String refreshToken, {String username = 'Usuario OIDC', String role = 'user'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_role', role);
    await prefs.setString('username', username);
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['access_token']);
        await prefs.setString('user_role', data['role'] ?? 'user');
        await prefs.setString('username', data['username'] ?? username);
        return data;
      } catch (e) {
        throw Exception('Error al procesar la respuesta del servidor.');
      }
    } else {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error de autenticación');
      } catch (_) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
    }
  }

  // ==========================================
  // TENANTS DEL USUARIO (para el filtro del historial)
  // ==========================================

  /// Tenants visibles para el usuario autenticado (`user_tenants ∪ role_tenants`).
  static Future<List<Map<String, dynamic>>> getMyTenants() async {
    final headers = await _authHeaders();
    final response = await _client.get(
      Uri.parse('$baseUrl/tenants/my-tenants'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data['tenants'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Error al cargar tenants');
    } catch (_) {
      throw Exception('Error del servidor (${response.statusCode})');
    }
  }

  // ==========================================
  // ALERTAS ENRIQUECIDAS POR IA (spec 018)
  // ==========================================

  static Future<List<AlertItem>> _parseAlertList(http.Response response) async {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = (data['items'] as List?) ?? const [];
      return items
          .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Error al cargar alertas');
    } catch (_) {
      throw Exception('Error del servidor (${response.statusCode})');
    }
  }

  /// Alertas activas (`status='firing'`) visibles para el usuario.
  static Future<List<AlertItem>> getRecentAlerts({int limit = 50}) async {
    final headers = await _authHeaders();
    final response = await _client.get(
      Uri.parse('$baseUrl/alerts/recent?limit=$limit'),
      headers: headers,
    );
    return _parseAlertList(response);
  }

  /// Historial de alertas con filtros y paginación (spec 018).
  static Future<AlertPage> getAlertHistory({
    int limit = 20,
    int offset = 0,
    String? tenantId,
    String? status,
    String? q,
  }) async {
    final headers = await _authHeaders();
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (tenantId != null && tenantId.isNotEmpty) params['tenant_id'] = tenantId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

    final query = Uri(queryParameters: params).query;
    final response = await _client.get(
      Uri.parse('$baseUrl/alerts/history?$query'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List?) ?? const [];
      final items = rawItems
          .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (data['total'] as num?)?.toInt() ?? items.length;
      return AlertPage(items: items, total: total);
    }
    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Error al cargar el historial');
    } catch (_) {
      throw Exception('Error del servidor (${response.statusCode})');
    }
  }

  /// Ajusta la criticidad de una alerta (requiere perfil alerts_manager).
  static Future<void> overrideAlertSeverity(int alertId, String severity) async {
    final headers = await _authHeaders();
    final response = await _client.patch(
      Uri.parse('$baseUrl/alerts/$alertId/severity'),
      headers: headers,
      body: jsonEncode({'severity': severity}),
    );
    if (response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al ajustar criticidad');
      } catch (_) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
    }
  }

  // ==========================================
  // NOTIFICACIONES PUSH (spec 018)
  // ==========================================

  /// Registra el token push del dispositivo para el usuario autenticado.
  static Future<void> registerDevice({
    required String fcmToken,
    String platform = 'android',
  }) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('$baseUrl/notifications/devices'),
      headers: headers,
      body: jsonEncode({'fcm_token': fcmToken, 'platform': platform}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al registrar el dispositivo');
      } catch (_) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
    }
  }

  /// Elimina el token push del usuario (al cerrar sesión).
  static Future<void> unregisterDevice(String fcmToken) async {
    final headers = await _authHeaders();
    final response = await _client.delete(
      Uri.parse('$baseUrl/notifications/devices?fcm_token=${Uri.encodeComponent(fcmToken)}'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al eliminar el dispositivo');
      } catch (_) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
    }
  }

  /// Obtiene los datos del usuario autenticado (roles, perfiles, tenants).
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final headers = await _authHeaders();
    final response = await _client.get(
      Uri.parse('$baseUrl/auth/user'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    }
    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Error obteniendo datos del usuario');
    } catch (_) {
      throw Exception('Error del servidor (${response.statusCode})');
    }
  }
}
