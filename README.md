# anomalia-mobile

Aplicación **Flutter** (Android) de **Anomalia**: consulta de alertas enriquecidas por IA, con
autenticación OIDC y configuración de servidor en runtime.

## Stack

- **Flutter** / **Dart** `^3.13.2` (Android principal; iOS/web/Linux/macOS/Windows soportados)
- **http**, **shared_preferences**, **url_launcher** (OIDC vía navegador), **app_links** (deep links)
- **firebase_core** / **firebase_messaging** / **flutter_local_notifications** (push FCM, inactivo sin `google-services.json`)

## Características

- Login local y **OIDC** (modos `local`, `local_only`, `hybrid`, `oidc_only`)
- Configuración del servidor en runtime (pantalla `ServerConfigScreen`, URL vacía por defecto; se preconfigura con el **QR de la web**)
- Listado de alertas (recientes + historial) con filtros, paginación y override de severidad
- Push FCM (requiere `google-services.json`; sin él la app funciona igual)

## Estructura

```
lib/
  main.dart                 # home, deep links (anomalia://callback, anomalia://config)
  screens/                  # login, alerts, server_config
  services/                 # api_service, notification_service
  models/                   # alert_model
android/ ios/ linux/ macos/ windows/ web/
assets/ test/
```

## Requisitos

- Flutter SDK `^3.13.2`
- Android SDK para builds Android

## Comandos

```bash
flutter pub get
flutter analyze
flutter test --dart-define=FLUTTER_TEST=true
```

## Configuración del servidor

La app arranca sin servidor configurado. Ingresá la URL del gateway, p. ej.:
`https://192.168.1.27/api/v1` (o escaneá el QR de la consola web). También podés
pre-cargarla al compilar: `--dart-define=API_BASE_URL=https://192.168.1.27/api/v1`.

## Build

```bash
flutter build apk --debug     # local / testing
flutter build apk --release   # requiere keystore de firma (ver CONTRIBUTING)
```

Guía de prueba en celular real: [`../anomalia-meta/docs/mobile/testing-on-device.md`](../anomalia-meta/docs/mobile/testing-on-device.md).

## Licencia

[Apache-2.0](./LICENSE)
