import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'server_config_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _loadingMore = false;
  List<AlertItem> _recentAlerts = [];
  List<AlertItem> _historyAlerts = [];

  List<String> _userRoles = const [];
  List<String> _userProfiles = const [];
  String _username = '';
  String _userRole = '';
  List<Map<String, dynamic>> _tenants = const [];
  bool _hasAccessAlerts = false;

  int _historyTotal = 0;
  int _historyOffset = 0;
  final int _historyLimit = 20;
  String? _historyStatus;
  String? _historyTenantId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadUserContext();
    await _fetchAlerts();
    if (mounted) setState(() => _isLoading = false);
  }

  bool _isAdmin(List<String> roles) {
    final r = roles.map((e) => e.toLowerCase()).toSet();
    return r.contains('admin');
  }

  Future<void> _loadUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'Usuario';
    final role = prefs.getString('user_role') ?? 'user';
    try {
      final userData = await ApiService.getCurrentUser();
      final roles = <String>[
        ...((userData['roles'] as List?)?.map((e) => e.toString()) ?? []),
      ];
      final roleStr = (userData['role'] as String?)?.isNotEmpty ?? false
          ? (userData['role'] as String)
          : role;
      final profiles = <String>[
        ...((userData['profiles'] as List?)?.map((e) => e.toString()) ?? []),
      ];
      final admin = _isAdmin(roles) || (roleStr.toLowerCase() == 'admin');
      final hasAccess =
          admin || profiles.contains('access_alerts') || roles.contains('admin');
      final tenants = await ApiService.getMyTenants();
      setState(() {
        _username = username;
        _userRole = roleStr;
        _userRoles = roles;
        _userProfiles = profiles;
        _tenants = tenants;
        _hasAccessAlerts = hasAccess;
      });
    } catch (e) {
      final admin = role.toLowerCase() == 'admin';
      setState(() {
        _username = username;
        _userRole = role;
        _userRoles = admin ? ['admin'] : [role];
        _hasAccessAlerts = admin;
      });
    }
  }

  Future<void> _fetchAlerts() async {
    if (!_hasAccessAlerts) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        ApiService.getRecentAlerts(limit: 50),
        ApiService.getAlertHistory(limit: _historyLimit, offset: 0, q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(), status: _historyStatus, tenantId: _historyTenantId),
      ]);
      if (!mounted) return;
      setState(() {
        _recentAlerts = results[0] as List<AlertItem>;
        final page = results[1] as AlertPage;
        _historyAlerts = page.items;
        _historyTotal = page.total;
        _historyOffset = _historyLimit;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar alertas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_loadingMore || _historyAlerts.length >= _historyTotal) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ApiService.getAlertHistory(
        limit: _historyLimit,
        offset: _historyOffset,
        q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _historyStatus,
        tenantId: _historyTenantId,
      );
      if (!mounted) return;
      setState(() {
        _historyAlerts = [..._historyAlerts, ...page.items];
        _historyOffset = _historyOffset + _historyLimit;
        _historyTotal = page.total;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar más alertas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyHistoryFilters() async {
    setState(() => _isLoading = true);
    try {
      final page = await ApiService.getAlertHistory(
        limit: _historyLimit,
        offset: 0,
        q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _historyStatus,
        tenantId: _historyTenantId,
      );
      if (!mounted) return;
      setState(() {
        _historyAlerts = page.items;
        _historyTotal = page.total;
        _historyOffset = _historyLimit;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.redAccent;
      case 'high':
        return Colors.deepOrangeAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.blueAccent;
      default:
        return Colors.blueGrey;
    }
  }

  String _sevLabel(String s) => (s.isEmpty ? 'info' : s).toUpperCase();

  bool _canManage() {
    final roles = _userRoles.map((e) => e.toLowerCase()).toSet();
    final profiles = _userProfiles.map((e) => e.toLowerCase()).toSet();
    return roles.contains('admin') || profiles.contains('alerts_manager');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_role');
    await prefs.remove('username');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _changeServer() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServerConfigScreen()),
    );
  }

  Widget _detailBlock(String title, String body) {
    if (body.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }

  Widget _buildAlertsList(
    List<AlertItem> alerts,
    String emptyMessage, {
    bool isHistory = false,
  }) {
    if (alerts.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: isHistory ? _applyHistoryFilters : _fetchAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: alerts.length + (isHistory && _historyAlerts.length < _historyTotal ? 1 : 0),
        itemBuilder: (context, index) {
          if (isHistory && index == alerts.length && _historyAlerts.length < _historyTotal) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : TextButton.icon(
                        onPressed: _loadMoreHistory,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Ver más'),
                      ),
              ),
            );
          }
          final alert = alerts[index];
          final color = _severityColor(alert.severity);
          final showOverride = _canManage();
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Icon(
                  alert.isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
                  color: Colors.white,
                ),
              ),
              title: Text(
                alert.alertname,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${alert.status.toUpperCase()} · ${_sevLabel(alert.severity)}'
                '${alert.tenantName.isNotEmpty ? ' · ${alert.tenantName}' : ''}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip('SEV: ${_sevLabel(alert.severity)}', color),
                          _chip('STATUS: ${alert.status.toUpperCase()}', alert.isFiring ? Colors.red : Colors.green),
                          if (alert.hasAiError)
                            _chip('IA no disponible', Colors.orange),
                          if (alert.hasEmailError)
                            _chip('Email no enviado', Colors.red),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _detailBlock('Resumen', alert.displaySummary),
                      if (alert.aiRootCause.isNotEmpty)
                        _detailBlock('Causa probable', alert.aiRootCause),
                      if (alert.aiChecks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Opciones a revisar:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        const SizedBox(height: 4),
                        ...alert.aiChecks.map(
                          (check) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                Expanded(child: Text(check)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (alert.description.isNotEmpty)
                        _detailBlock('Descripción', alert.description),
                      if (!alert.isFiring && alert.endsAt.isNotEmpty)
                        _detailBlock('Resuelta', alert.endsAt),
                      if (alert.startsAt.isNotEmpty)
                        _detailBlock('Inició', alert.startsAt),
                      if (alert.severityOverrideBy.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Criticidad ajustada por ${alert.severityOverrideBy}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      if (showOverride && alert.id != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _overrideDropdown(alert),
                        ),
                      if (alert.generatorUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(alert.generatorUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se pudo abrir el enlace'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Ver en vmalert'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text, Color bg) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: bg.withOpacity(0.2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _overrideDropdown(AlertItem alert) {
    final current = alert.severity.isEmpty ? 'info' : alert.severity;
    final values = ['critical', 'high', 'medium', 'low', 'info'];
    return Row(
      children: [
        const Text('Override severidad: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: values.contains(current) ? current : 'info',
          items: values.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
          onChanged: (v) async {
            if (v == null || v == current) return;
            try {
              await ApiService.overrideAlertSeverity(alert.id!, v);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Severidad actualizada a ${v.toUpperCase()}')),
              );
              _fetchAlerts();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al ajustar criticidad: $e'), backgroundColor: Colors.red),
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasAccessAlerts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alertas'), actions: [
          IconButton(icon: const Icon(Icons.dns_outlined), onPressed: _changeServer, tooltip: 'Cambiar servidor'),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Cerrar sesión'),
        ]),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                SizedBox(height: 12),
                Text('Requiere el perfil access_alerts para ver las alertas.', textAlign: TextAlign.center),
                SizedBox(height: 4),
                Text('Contactá al administrador.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0891B2),
        foregroundColor: Colors.white,
        title: const Text('Centro de Alertas e Inteligencia'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bolt), text: 'Recientes'),
            Tab(icon: Icon(Icons.history), text: 'Historial BD'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.dns_outlined), onPressed: _changeServer, tooltip: 'Cambiar servidor'),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Cerrar sesión'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAlerts, tooltip: 'Actualizar'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsList(_recentAlerts, 'No hay alertas recientes para tus tenants.'),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) {},
                      decoration: InputDecoration(
                        labelText: 'Buscar (alertname, resumen, descripción)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applyHistoryFilters();
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _applyHistoryFilters(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _historyStatus,
                            decoration: const InputDecoration(labelText: 'Estado'),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Todos')),
                              DropdownMenuItem(value: 'firing', child: Text('Firing')),
                              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                            ],
                            onChanged: (v) {
                              setState(() => _historyStatus = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _historyTenantId,
                            decoration: const InputDecoration(labelText: 'Tenant'),
                            items: <DropdownMenuItem<String>>[
                              const DropdownMenuItem(value: null, child: Text('Todos')),
                              ..._tenants.map((t) => DropdownMenuItem(
                                    value: t['id']?.toString(),
                                    child: Text(t['name']?.toString() ?? t['id']?.toString() ?? ''),
                                  )),
                            ],
                            onChanged: (v) {
                              setState(() => _historyTenantId = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _applyHistoryFilters,
                        icon: const Icon(Icons.filter_alt),
                        label: const Text('Aplicar filtros'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildAlertsList(
                  _historyAlerts,
                  'Sin resultados para el filtro aplicado.',
                  isHistory: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
