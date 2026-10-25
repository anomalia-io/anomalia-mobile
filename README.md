# anomalia-mobile

**Anomalia Mobile** es el complemento móvil oficial para Android de la plataforma **Anomalía**. Su función principal es permitir la recepción y consulta en tiempo real de alertas enriquecidas por Inteligencia Artificial generadas por el sistema.

## Características Principales

- **Recepción de Alertas**: Visualización rápida del listado de alertas recientes e historial con filtros y detalles avanzados.
- **Notificaciones Push (FCM)**: Integración con Firebase Cloud Messaging para notificar al instante en el dispositivo cuando ocurre una incidencia.
- **Configuración Rápida por Escaneo de QR**: En el primer arranque, la aplicación permite escribir la URL del servidor manualmente o **escanear directamente el código QR** provisto por la interfaz web de Anomalía para una autoconfiguración inmediata.
- **Autenticación OIDC / SSO**: Soporte para inicio de sesión seguro integrado con el gateway.

## Configuración del Servidor

En el primer inicio, la app solicitará configurar la URL del gateway del sistema:
- **Opción manual**: Ingresando la URL (ej. `https://192.168.1.X/api/v1`).
- **Opción con QR**: Tocando el botón **"Escanear QR"** para capturar con la cámara el código QR expuesto en la consola web de Anomalía.

## Descargar la Aplicación

Las versiones firmadas y listas para instalar (`anomalia.apk`) se publican automáticamente en la sección de [Releases](https://github.com/anomalia-io/anomalia-mobile/releases), junto a su respectivo archivo `checksums.txt` (SHA-256) para verificar la integridad del archivo.

## Stack Tecnológico

- **Flutter / Dart** (`^3.13.2`)
- **mobile_scanner** (Escáner de códigos QR)
- **firebase_messaging** / **flutter_local_notifications** (Notificaciones push)
- **http**, **shared_preferences**, **url_launcher**, **app_links**

## Documentación

- [Aplicación Flutter](docs/flutter-app.md)
- [Prueba en un celular real](docs/testing-on-device.md)
- [Releases y APK](docs/releases.md)

## Licencia

[Apache-2.0](./LICENSE)
