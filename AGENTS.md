# AGENTS.md — anomalia-mobile

Guía para agentes y desarrolladores que trabajen en **`anomalia-mobile`**: la aplicación
**Flutter** (Android principal) de **Anomalia**, para consultar alertas enriquecidas por IA.

> Este repo es parte del proyecto multi-repo **Anomalia** (`anomalia-io`). Las specs SSD y la
> gobernanza viven en el repo privado `anomalia-meta`. Trabajá **una sesión por repo**.

## Stack

- **Flutter** / **Dart** `^3.13.2` (Android principal; iOS/web/Linux/macOS/Windows soportados).
- **http**, **shared_preferences**, **url_launcher** (OIDC vía navegador externo), **app_links** (deep links).
- **firebase_core** / **firebase_messaging** / **flutter_local_notifications** (push FCM, inactivo sin `google-services.json`).

## Comandos

```bash
flutter pub get
flutter analyze
flutter test --dart-define=FLUTTER_TEST=true   # recomendado: saltea init de Firebase/FCM en tests
gitleaks dir .                                 # escaneo de secretos (obligatorio)
```

Build:

```bash
flutter build apk --debug      # local / testing
flutter build apk --release    # requiere keystore de firma (ver CONTRIBUTING)
```

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

## Convenciones

- **Sin secretos**: `google-services.json`, keystores y `key.properties` **nunca** se versionan
  (ya están en `.gitignore`).
- **Commits firmados**: `commit.gpgsign=true` con SSH (heredado del `~/.gitconfig` global).
- **Un PR por repo**: si un cambio impacta otro repo, abrí una sesión en ese repo.

## Documentación

- [Aplicación Flutter](docs/flutter-app.md)
- [Prueba en celular real](docs/testing-on-device.md)
- [Releases y APK](docs/releases.md)

## Enlaces

- Specs SSD y gobernanza: repo privado `anomalia-meta` (`specs/`).
- API que consume: [`anomalia-backend`](https://github.com/anomalia-io/anomalia-backend).
