# Aplicación Móvil

La aplicación móvil desarrollada en **Flutter** permite a los operadores recibir las alertas analizadas por la IA y consultar su historial.

> **Push (FCM) inactivas hasta configurar ambas puntas.** La app funciona sin
> `google-services.json`: al no existir, `Firebase.initializeApp()` falla de forma controlada y
> `notification_service.dart` deja `_fcmAvailable=false`, por lo que el registro de dispositivo
> (`registerDeviceIfPossible`) retorna temprano. Para recibir push hacen falta el
> `google-services.json` de Android en `android/app/` (ignorado por git; paquete
> `com.anomalia.anomaliagw_mobile`) **y** que el backend tenga cargada la service account JSON de
> Firebase con `push_enabled=true`. iOS no tiene `GoogleService-Info.plist` ni setup de Firebase:
> no está listo para release.

## Características
- Autenticación OIDC abriendo el navegador externo con `url_launcher`.
- Enlace profundo con `app_links` (deep links `anomalia://callback` y `anomalia://config`).
- Configuración del servidor en runtime (pantalla `ServerConfigScreen`, URL vacía por defecto).
- Visualización de alertas (recientes + historial) con filtros, paginación y override de severidad.

## Configuración del servidor
La app arranca sin servidor configurado: `services/api_service.dart` lee
`API_BASE_URL` vía `--dart-define` o vacío, y muestra `ServerConfigScreen`. El usuario
ingresa la URL del gateway (p. ej. `https://mi-servidor.example.com/api/v1`); `normalizeBaseUrl`
agrega `/api/v1` si falta. También se puede preconfigurar con el **QR de la web**:
el login (`login.html`) y el panel admin (`index.html`) muestran la URL y un QR
colapsados por defecto (se despliegan al click). El QR codifica
`anomalia://config?base_url=<origin>`.

## Autenticación OIDC (spec 020)
La pantalla de login consulta `GET /api/v1/settings/auth` y respeta el modo
configurado:

- `local` / `local_only`: solo formulario local.
- `hybrid` (default): formulario local + botón OIDC.
- `oidc_only`: solo botón OIDC.

El botón OIDC llama a `GET /api/v1/oidc/login?session_type=mobile&redirect_uri=anomalia://callback`
y abre la URL del IdP en el navegador externo (`url_launcher`). El IdP redirige
al deep link `anomalia://callback?code=…&state=…`, capturado en `main.dart` con
`AppLinks` (`getInitialAppLink()` + `uriLinkStream`); la app entonces llama a
`GET /api/v1/oidc/callback` (`completeOidcMobile`) que devuelve JSON
`{access_token, username, role}` y lo guarda en `SharedPreferences`
(`auth_token`) antes de navegar a la pantalla de alertas.

El esquema `anomalia` debe estar declarado en `AndroidManifest.xml`
(intent-filter `VIEW`/`BROWSABLE`) y en `ios/Runner/Info.plist`
(`CFBundleURLTypes`).

## Red, TLS y QR

El celular y el host deben estar en la misma LAN. El deploy autofirmado usa por defecto la
**IP LAN del backend** como CN/SAN (además de `anomalia.local`, `localhost` y `127.0.0.1`),
así que configurá `https://<IP_LAN>/api/v1`. Si desplegaste con `--hostname`, usá ese nombre y
verificá que el SAN lo cubra. El QR codifica `anomalia://config?base_url=<origin>` y usa
`window.location.origin` de la web: abrí el panel con la IP (o el hostname provisto) para que el
QR apunte a la dirección correcta.

Los builds debug (`flutter run`, `flutter build apk --debug`) aceptan la CA local mediante
`badCertificateCallback` en `kDebugMode`. Los builds release usan TLS estricto: la CA local debe
 estar instalada y confiada en el dispositivo. El proyecto no declara una configuración de red
 de Android; no hay un mecanismo de configuración adicional más allá de la CA y el callback de
 debug.

## Versiones y comandos

- Flutter 3.47.2 en CI, Dart `^3.13.2` (`pubspec.yaml`).
- `flutter pub get`
- `flutter analyze --no-fatal-infos`
- `flutter test --dart-define=FLUTTER_TEST=true`
- `flutter build apk --debug` / `flutter build apk --release`

## Pruebas
- Unitarias: `flutter test --dart-define=FLUTTER_TEST=true`.
- En celular real: ver [testing-on-device.md](testing-on-device.md).

