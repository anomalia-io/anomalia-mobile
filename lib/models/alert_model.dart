/// Alerta enriquecida por IA (spec 018). Refleja el payload de
/// `GET /api/v1/alerts/recent` y `/history` (`alerts_router._serialize`).
class AlertItem {
  final int? id;
  final int? tenantId;
  final String tenantName;
  final String alertname;
  final String severity;
  final String severitySource;
  final String summary;
  final String description;
  final String aiSummary;
  final String aiRootCause;
  final List<String> aiChecks;
  final String status;
  final String generatorUrl;
  final String severityOverrideBy;
  final String startsAt;
  final String endsAt;
  final String aiError;
  final String emailStatus;
  final String emailError;

  AlertItem({
    this.id,
    this.tenantId,
    required this.tenantName,
    required this.alertname,
    required this.severity,
    required this.severitySource,
    required this.summary,
    required this.description,
    required this.aiSummary,
    required this.aiRootCause,
    required this.aiChecks,
    required this.status,
    required this.generatorUrl,
    required this.severityOverrideBy,
    required this.startsAt,
    required this.endsAt,
    this.aiError = '',
    this.emailStatus = '',
    this.emailError = '',
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['ai_checks'];
    return AlertItem(
      id: json['id'],
      tenantId: json['tenant_id'],
      tenantName: json['tenant_name'] ?? '',
      alertname: json['alertname'] ?? 'Alerta sin nombre',
      severity: json['severity'] ?? 'info',
      severitySource: json['severity_source'] ?? '',
      summary: json['summary'] ?? '',
      description: json['description'] ?? '',
      aiSummary: json['ai_summary'] ?? '',
      aiRootCause: json['ai_root_cause'] ?? '',
      aiChecks: rawChecks is List
          ? rawChecks.map((e) => e.toString()).toList()
          : <String>[],
      status: json['status'] ?? 'firing',
      generatorUrl: json['generator_url'] ?? '',
      severityOverrideBy: json['severity_override_by'] ?? '',
      startsAt: json['starts_at'] ?? '',
      endsAt: json['ends_at'] ?? '',
      aiError: json['ai_error'] ?? '',
      emailStatus: json['email_status'] ?? '',
      emailError: json['email_error'] ?? '',
    );
  }

  bool get isFiring => status == 'firing';

  bool get isCritical => severity == 'critical' || severity == 'high';

  /// El análisis IA falló (se conservan los datos originales de Alertmanager).
  bool get hasAiError => aiError.isNotEmpty;

  /// La entrega por email a los destinatarios del tenant falló o no había SMTP
  /// (spec 018). La tarjeta lo marca igual que la web.
  bool get hasEmailError =>
      emailStatus == 'failed' || emailStatus == 'not_configured';

  /// Resumen a mostrar en la tarjeta: IA si existe, si no el original.
  String get displaySummary => aiSummary.isNotEmpty ? aiSummary : summary;
}

/// Página del historial de alertas: items + total para paginar (spec 018).
class AlertPage {
  final List<AlertItem> items;
  final int total;

  AlertPage({required this.items, required this.total});
}
