# anomalia-mobile

**Anomalia Mobile** es el complemento móvil oficial para Android de la plataforma **Anomalía**. Su función principal es permitir la recepción y consulta en tiempo real de alertas enriquecidas por Inteligencia Artificial generadas por el sistema.

## 👤 Para Usuario Final (usar la app)

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

La app se conecta al backend a través de los endpoints API del gateway (consultar la docs del backend para URLs completas).