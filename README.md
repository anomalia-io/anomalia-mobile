# anomalia-mobile

**Anomalia Mobile** es el complemento móvil oficial para Android de la plataforma **Anomalía**. Su función principal es permitir la recepción y consulta en tiempo real de alertas enriquecidas por Inteligencia Artificial generadas por el sistema.

## 👤 Para Usuario Final (probar la app móvil)

No necesitas compilar ni modificar el código para usar la app. Los pasos son:

### 1. Descargar versión instaladora
Las versiones firmadas y listas para instalar (`anomalia.apk`) se publican automáticamente en la sección de [Releases](https://github.com/anomalia-io/anomalia-mobile/releases), junto a su respectivo archivo `checksums.txt` (SHA-256) para verificar la integridad del archivo.

### 2. Primera ejecución
Al abrir la app por primera vez, solicitá la configuración del servidor:
- **Opción manual**: Ingresando la URL (ej. `https://192.168.1.X/api/v1`)
- **Opción QR**: Tocando el botón **"Escanear QR"** para capturar con la cámara el código QR expuesto en la consola web de Anomalía (gateway)

### 3. Usar la app
- Visualizar listado de alertas recientes e historial con filtros
- Recibir notificaciones push (FCM) cuando ocurre una incidencia
- Escanear nuevos códigos QR para reconfigurar la URL del servidor

### 4. Compilar desde fuente (solo si querés construir el APK tú mismo)
```bash
cd anomalia-mobile
flutter pub get
flutter analyze
flutter test --dart-define=FLUTTER_TEST=true    # modo test (saltea Firebase/FCM init)
```

### 5. Build para producción
```bash
# APK release
flutter build apk --release

# iOS release
flutter build ios --release
```

### 6. Auth SSO/OIDC (si el gateway está configurado)
- Flow: navegador externo (`url_launcher`) → deep link (`app_links`)
- Issuer: IP LAN o `anomalia.local`
- Mobile: verificar deep link `anomalia://callback` funciona
- Credenciales por defecto: `test@anomalia.local` / `testpass` (override con `--user`/`--password`)

## 👨‍💻 Para Contribuidor/Developer

Modificás la app Flutter, flows de auth, notificaciones o QR scanning. Flujo desarrollo:

### 1. Entorno
```bash
cd anomalia-mobile
flutter pub get                          # obtener dependencias
flutter analyze                        # análisis estático (sin warnings)
flutter test                           # tests unitarios
flutter test --dart-define=FLUTTER_TEST=true  # modo test (sin Firebase/FCM init)
```

### 2. Flujo SSO/OIDC (si modificás autenticación)
- Probar con IdP mock: `anomalia-backend/scripts/oidc-test/run-test-idp.sh --configure --groups viewer`
- Usuario: `test@anomalia.local` / `testpass`
- Roles: `--groups owner,viewer` o `--sin-perfiles` (sin claims de rol)
- Mobile: verificar deep link `anomalia://callback` funciona correctamente
- Variables de entorno opcionales: `OIDC_TEST_PORT`, `OIDC_TEST_ISSUER`, `OIDC_TEST_GROUPS`, etc.

### 3. Convenciones de code
- Arquitectura limpia + Material Design
- OIDC flows seguros (`url_launcher` abre navegador externo)
- `app_links` capturar deep link de retorno
- **Nunca** commit `.env` files ni credenciales
- `FLUTTER_TEST=true` en tests unitarios (gate en `main.dart` por `bool.fromEnvironment('FLUTTER_TEST')`)
- Usar `shared_preferences` para estado persistente local
- `http` client para llamadas API al backend

### 4. Estructura
```
lib/               # código Dart principal
test/              # tests unitarios y de widget
docs/              # documentación del repo (flutter-app.md, testing-on-device.md, releases.md)
android/           # configuración Android specific
ios/               # configuración iOS specific
```
- `pubspec.yaml` - dependencias: `http`, `shared_preferences`, `url_launcher`, `app_links`, `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
- `main.dart` - gate `bool.fromEnvironment('FLUTTER_TEST')` para saltear Firebase en tests

### 5. Commiteo
```bash
git add .
git commit -S -m "feat: <descripción>"
git push origin main
```

### 6. Endpoints relacionados (desde el backend)
- `GET /api/v1/alerts` - listado de alertas
- `POST /api/v1/system/backup/import` - importar backup (auth requerido)
- Webhook de alertas desde Alertmanager

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
