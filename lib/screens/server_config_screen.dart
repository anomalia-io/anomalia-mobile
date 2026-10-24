import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

/// Configuración del servidor (gateway) al que se conecta la app.
///
/// La URL se obtiene desde la web: aparece en la página de login y en
/// «Configuración General» (o escaneando el QR que abre `anomalia://config`).
class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiService.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Ingresá la URL del servidor.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await ApiService.probeServer(raw);
      final normalized = await ApiService.setBaseUrl(raw);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Servidor configurado: $normalized')),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'No se pudo conectar con el servidor. Verificá la URL. (${e.toString().replaceAll("Exception: ", "")})';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerView(
          onScanned: (scannedValue) {
            String url = scannedValue;
            // Parsear deep link anomalia://config?base_url=... si viene en ese formato
            try {
              final uri = Uri.parse(scannedValue);
              if (uri.scheme == 'anomalia' && uri.host == 'config') {
                final qBase = uri.queryParameters['base_url'];
                if (qBase != null && qBase.isNotEmpty) {
                  url = qBase;
                }
              }
            } catch (_) {}

            setState(() {
              _urlController.text = url;
            });
            _saveAndTest();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFirstRun = !Navigator.canPop(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Servidor'),
        automaticallyImplyLeading: !isFirstRun,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.dns_outlined, size: 56, color: Colors.blueGrey),
                const SizedBox(height: 16),
                const Text(
                  'Servidor de Anomalía',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresá la URL del gateway o escaneá el código QR de la consola web.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'URL del servidor',
                    hintText: 'https://mi-servidor',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ejemplo: https://anomalia.local  (se agrega /api/v1 automáticamente).',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saveAndTest,
                            icon: const Icon(Icons.save),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            label: const Text('Probar y guardar', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _openQrScanner,
                            icon: const Icon(Icons.qr_code_scanner),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            label: const Text('Escanear QR', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QrScannerView extends StatelessWidget {
  final ValueChanged<String> onScanned;

  const QrScannerView({super.key, required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR de Configuración')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              final val = barcode.rawValue!;
              // Evitar múltiples pops
              Navigator.pop(context);
              onScanned(val);
              break;
            }
          }
        },
      ),
    );
  }
}
