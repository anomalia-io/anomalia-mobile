# anomalia-mobile

**Anomalia Mobile** es el complemento móvil oficial para **Android** de la plataforma **Anomalía**.
Permite recibir y consultar alertas enriquecidas por IA. iOS está presente en el árbol del
proyecto pero **no está listo para producción**: no hay `GoogleService-Info.plist` ni setup de
Firebase para iOS.

## 👤 Para Usuario Final (usar la app)

No necesitas compilar ni modificar el código para usar la app.

### 1. Descargar versión instaladora

Los artefactos publicados en [Releases](https://github.com/anomalia-io/anomalia-mobile/releases)
se llaman `anomalia.apk` y vienen con `checksums.txt` (SHA-256). Verificá la integridad con:

```bash
sha256sum -c checksums.txt
```

> Limitación conocida: `android/app/build.gradle.kts` todavía usa la configuración de firma
> `debug` para el tipo `release`. El workflow de release genera un keystore y `key.properties`,
> pero el Gradle actual no los consume; por eso el APK publicado **no debe considerarse firmado
> con una clave de distribución**. Ver [releases.md](docs/releases.md).

### 2. Primera ejecución

Al abrir la app por primera vez, solicitá la configuración del servidor:

- **Manual**: ingresá la URL, p. ej. `https://192.168.1.50/api/v1`.
- **QR**: tocá **“Escanear QR”** para capturar el código expuesto en la consola web.

La celular y la PC deben estar en la **misma LAN**. `anomalia.local` no resuelve en el celular
(no comparte el `/etc/hosts` del host): usá la **IP LAN del servidor**. El certificado del gateway
debe tener esa IP en su SAN y el cliente debe confiar en la CA local; si el SAN no coincide, la
conexión fallará.

### 3. Usar la app

- Visualizar alertas recientes e historial con filtros.
- Recibir notificaciones push (FCM) cuando el backend está configurado.
- Escanear nuevos códigos QR para reconfigurar la URL del servidor.

### 4. Compilar desde fuente (Android-first)

Versión del toolchain: Flutter **3.47.2** en CI, Dart **^3.13.2** (`pubspec.yaml`).

```bash
cd anomalia-mobile
flutter pub get
flutter analyze --no-fatal-infos
flutter test --dart-define=FLUTTER_TEST=true    # modo test (saltea Firebase/FCM init)
flutter run -d <device_id>                      # debug en celular/Android
flutter build apk --debug
flutter build apk --release
```

No hay `flutter build ios --release` soportado: iOS no tiene configuración de Firebase ni flujo de
release en este repo.

### 5. Auth SSO/OIDC (si el gateway está configurado)

- Flow: navegador externo (`url_launcher`) → deep link (`app_links`) `anomalia://callback`.
- El QR de configuración usa el deep link `anomalia://config`.
- Issuer: usá la **IP LAN**, no `anomalia.local`, de forma consistente entre el navegador del
  celular y el backend.
- Deep links declarados: `anomalia://callback` y `anomalia://config`.

### 6. Push (FCM)

Se necesitan **las dos piezas**:

1. Backend: service account JSON de Firebase cargado en la configuración push y
   `push_enabled=true` (`PUT /api/v1/system/push`). El backend guarda la service account en la BD
   y nunca la devuelve al navegador.
2. Android: `android/app/google-services.json`, ignorado por git. El paquete es
   `com.anomalia.anomaliagw_mobile`.

Sin `google-services.json`, `Firebase.initializeApp()` falla de forma controlada y el registro de
dispositivo no se intenta. En builds **debug** se acepta la CA local mediante
`badCertificateCallback` (`kDebugMode`); en builds **release** el TLS es estricto y la CA debe
 estar instalada y confiada en el dispositivo. El proyecto no declara una configuración de red
 de Android: el comportamiento se explica por la confianza en la CA y por el callback de debug.

Guías detalladas: [flutter-app.md](docs/flutter-app.md),
[testing-on-device.md](docs/testing-on-device.md), [releases.md](docs/releases.md).

## Licencia

- Código: [Apache-2.0](./LICENSE)
- Documentación: [CC BY-SA 4.0](./LICENSE-DOCS)
