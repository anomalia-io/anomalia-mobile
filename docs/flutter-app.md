# Aplicación Móvil

La aplicación móvil desarrollada en **Flutter** permite a los operadores recibir las alertas analizadas por la IA y consultar su historial.

> **Push (FCM) inactivas por defecto.** La app funciona sin `google-services.json`: al no
> existir, `Firebase.initializeApp()` falla de forma controlada y `notification_service.dart`
> deja `_fcmAvailable=false`, por lo que el registro de dispositivo (`registerDeviceIfPossible`)
> retorna temprano. Al agregar `google-services.json` en `android/app/`, FCM se activa solo.

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

## Pruebas
- Unitarias: `flutter test --dart-define=FLUTTER_TEST=true`.
- En celular real: ver [testing-on-device.md](testing-on-device.md).

