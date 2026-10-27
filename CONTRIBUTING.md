# CONTRIBUTING.md - Anomalia Mobile

## 👨‍💻 Flujo de Desarrollo (SSD + Flutter)

Los cambios en la app Flutter deben seguir el protocolo **Specs-Anchored Development (SSD)** y las convenciones del proyecto mobile.

### ⚠️ Antes de Implementar

1. **Cargar skill** `anomalia-flutter-mobile-skill` (segúdir `AGENTS.md §3.4`)

2. **Leer spec relevante** según el cambio:
   - `specs/018-alert-ai-analysis-and-delivery.md` - Entrega de alertas IA
   - `specs/017-notifications.md` - Notificaciones al usuario
   - `specs/020-oidc-sso-integration.md` - Integración OIDC/SSO

3. **Verificar `constitution.md`** - Principios rectores del proyecto

4. **Ejecutar validaciones**:
   - `flutter analyze` - Sin warnings de estilo
   - `flutter test` - Todos los tests deben pasar
   - `flutter test --dart-define=FLUTTER_TEST=true` - Modo test (saltea Firebase/FCM init)
   - Revisar que no hay secretos hardcodeados (strings `ctx7sk-`, `Bearer` de 20+ chars, keys RSA)

### 📝 Después de Implementar

1. **Actualizar spec** en `anomalia-meta/specs/` si el cambio altera comportamiento documentado:
   - Misma numeración: `NNN-titulo-en-kebab-case.md`
   - Si es nueva funcionalidad → crear spec nueva con número libre

2. **Actualizar `AGENTS.md`** en `anomalia-meta` si se agregan nuevas funciones o endpoints:
   - Agregar fila en tablas de skills/MCP
   - Nueva sección si corresponde (§3.5 flujo documentación)

3. **Invocar `@spec-sync`** desde la sesión `anomalia-mobile`:
   - El subagente lee `git status`, `git diff`, `git log -n 5`
   - Propone update en `anomalia-meta/specs/`
   - El usuario approbar y commit en `anomalia-meta`

4. **Commit con firma SSH**:
   ```bash
   git add .
   git commit -S -m "feat: <descripción del cambio>"
   git push origin main
   ```
   - **Obligatorio** el flag `-S` para firma SSH verificada
   - `user.signingkey = ~/.ssh/id_ed25519_personal.pub`
   - `user.email = jo.asd.xd@gmail.com`

### 📋 Checklist Pre-Commit

| Item | Verificar |
|------|-----------|
| Skill `anomalia-flutter-mobile-skill` cargada | ✅ |
| Spec relevante leída | ✅ |
| `constitution.md` revisada | ✅ |
| `flutter analyze` - sin warnings | ✅ |
| `flutter test` - todos pasan | ✅ |
| `flutter test --dart-define=FLUTTER_TEST=true` - todos pasan | ✅ |
| Sin secretos hardcodeados en código | ✅ |
| Commit con firma SSH (`-S`) | ✅ |
| `@spec-sync` invocado (si corresponde) | ✅ |

### 📱 Piles y Tests

```bash
# Instalar dependencias
flutter pub get

# Análisis estático
flutter analyze

# Ejecutar tests (modo test, sin Firebase init)
flutter test                            # tests unitarios
flutter test --dart-define=FLUTTER_TEST=true  # modo test obligatorio

# Compilar
flutter build apk --release            # APK release
flutter build ios --release            # iOS release

# Depuración local
flutter run -d android                  # en dispositivo/emulador Android
```

### 📱 Stack Tecnológico

- **Flutter / Dart** (`^3.13.2`)
- **mobile_scanner** (Escáner de códigos QR)
- **firebase_messaging** / **flutter_local_notifications** (Notificaciones push)
- **http**, **shared_preferences**, **url_launcher**, **app_links**

### 📄 Licencia

[Apache-2.0](./LICENSE)