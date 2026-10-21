import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/server_config_screen.dart';
import 'screens/alerts_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadBaseUrl();
  runApp(const AnomaliaApp());
}

class AnomaliaApp extends StatefulWidget {
  const AnomaliaApp({super.key});

  @override
  State<AnomaliaApp> createState() => _AnomaliaAppState();
}

class _AnomaliaAppState extends State<AnomaliaApp> {
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    const isTest = bool.fromEnvironment('FLUTTER_TEST');
    if (!isTest) {
      NotificationService.instance.initialize();
    }
  }

  Future<void> _initDeepLinks() async {
    // Link inicial (app abierta desde cero por el callback OIDC).
    final initial = await _appLinks.getInitialAppLink();
    if (initial != null) {
      await _handleCallback(initial);
    }

    // Links en caliente (app ya en primer plano).
    _appLinks.uriLinkStream.listen((uri) {
      _handleCallback(uri);
    });
  }

  Future<void> _handleCallback(Uri uri) async {
    if (uri.scheme != 'anomalia') return;

    // Deep link para preconfigurar servidor: anomalia://config?base_url=...
    if (uri.host == 'config') {
      final baseUrl = uri.queryParameters['base_url'] ?? uri.queryParameters['url'];
      if (baseUrl != null && baseUrl.isNotEmpty) {
        try {
          await ApiService.setBaseUrl(baseUrl);
          if (!mounted) return;
          _showMessage('Servidor configurado desde enlace');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          return;
        } catch (e) {
          _showMessage('Error configurando servidor: ${e.toString().replaceAll("Exception: ", "")}', isError: true);
        }
      }
      return;
    }

    // Deep link de callback OIDC: anomalia://callback
    if (uri.host != 'callback') return;

    final error = uri.queryParameters['error'] ?? uri.queryParameters['error_description'];
    if (error != null && error.isNotEmpty) {
      _showMessage('Error OIDC: $error', isError: true);
      return;
    }

    // Flujo principal: el IdP redirige con code/state y el backend completa el
    // intercambio devolviendo el token en JSON (spec 020).
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];

    String? token;
    String? username;
    String? role;

    if (code != null && state != null) {
      try {
        final result = await ApiService.completeOidcMobile(code, state);
        token = result['access_token'] as String?;
        username = result['username'] as String?;
        role = result['role'] as String?;
      } catch (e) {
        _showMessage('Error OIDC: ${e.toString().replaceAll("Exception: ", "")}', isError: true);
        return;
      }
    } else {
      // Compatibilidad: token directo en el deep link.
      token = uri.queryParameters['access_token'] ?? uri.queryParameters['token'];
      username = uri.queryParameters['username'];
      role = uri.queryParameters['role'];
    }

    if (token == null || token.isEmpty) {
      _showMessage('OIDC: no se recibió token.', isError: true);
      return;
    }

    await ApiService.saveOidcTokens(
      token,
      '',
      username: username ?? 'Usuario OIDC',
      role: role ?? '',
    );

    // Try to register FCM token after login
    NotificationService.instance.registerDeviceIfPossible();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AlertsScreen()),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'anomalIAGW',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF1E293B),
          onSurface: const Color(0xFFF1F5F9),
          primary: const Color(0xFF0891B2),
          onPrimary: Colors.white,
          outline: const Color(0xFF334155),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0891B2),
          foregroundColor: Colors.white,
        ),
      ),
      home: FutureBuilder<bool>(
        future: ApiService.hasConfiguredServer(),
        builder: (context, snapshot) {
          final configured = snapshot.data ?? false;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!configured) {
            return const ServerConfigScreen();
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
