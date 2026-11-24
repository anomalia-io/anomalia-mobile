# Prueba en un celular real

Guía para instalar y probar la aplicación móvil en un dispositivo Android físico.

> La app está orientada a **Android**. En Linux desktop el flujo SSO **no** funciona
> porque el deep link `anomalia://callback` no está registrado como handler de esquema
> (ver `specs/020-oidc-sso-integration.md`). Para desarrollo rápido se usa `flutter run`;
> para la prueba real usá un celular.

## 1. Checklist previo

- Celular y PC en la **misma red Wi‑Fi / LAN**.
- Stack desplegado y gateway accesible desde la LAN. IP LAN del host: **`<IP_LAN>`**
  (verificar con `ip -4 addr`).
- El gateway TLS expone `https://<IP_LAN>`. Nginx termina TLS con un leaf firmado por una
  **CA local**; el SAN debe cubrir la IP LAN y el cliente debe confiar en esa CA.
- **`anomalia.local` NO resuelve en el celular** (no comparte el `/etc/hosts` del host).
  Usar siempre la **IP LAN `<IP_LAN>`** desde el celular, con SAN/CA coherentes.

## 2. Debug vs release

| Build | Certificado de la CA local | Uso |
|-------|----------------------------|-----|
| `flutter run` / `flutter build apk --debug` | **Aceptado** (`badCertificateCallback` en `kDebugMode`, `services/api_service.dart`) | Prueba en celular |
| `flutter build apk --release` | TLS estricto: funciona solo si la CA está instalada y confiada en el dispositivo | Requiere CA confiada; sin configuración de red declarativa |

Para la prueba en celular usar **debug**. El proyecto no declara una configuración de red de Android adicional.

## 3. Preparar el celular (Android)

1. Ajustes → Información del teléfono → tocar **Número de compilación** 7 veces → activar
   **Opciones de desarrollador**.
2. Activar **Depuración por USB** (y **Depuración inalámbrica** si vas por Wi‑Fi).
3. Conectar por USB y aceptar **¿Permitir depuración USB?**.

## 4. Preparar la PC

- Instalar `adb` (Google platform-tools). En Debian/Ubuntu: `sudo apt install adb`.
- Verificar el dispositivo:
  ```bash
  adb devices        # debe listar el celular como "device" (no "unauthorized")
  ```
  - `unauthorized` → revisar el diálogo en el celular.
  - `no permissions` → faltan reglas udev (`/etc/udev/rules.d/51-android.rules`).

## 5. Instalar / ejecutar la app

### Opción A — USB + debug (recomendada)

```bash
cd anomalia-mobile
flutter devices                     # confirmar el id del celular
flutter run -d <device_id>          # compila debug (acepta el leaf de la CA local)
```

Atajo para pre-llenar la URL en `ServerConfigScreen`:

```bash
flutter run -d <device_id> --dart-define=API_BASE_URL=https://<IP_LAN>/api/v1
```

> El define **no** saltea la configuración: `hasConfiguredServer()` solo mira
> `SharedPreferences`, así que en el primer arranque la pantalla de configuración
> **igual aparece**, con el campo pre-cargado. Solo hay que tocar «Probar y guardar».

### Opción B — APK manual

```bash
cd anomalia-mobile
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Opción C — Wi‑Fi (Android 11+)

```bash
adb pair <ip_celu>:<puerto>     # el puerto/código salen en Opciones de desarrollador
adb connect <ip_celu>:<puerto>
flutter run -d <ip_celu>:<puerto>
```

## 6. Configurar el servidor en la app

En el primer arranque la app muestra **ServerConfigScreen** (la URL viene vacía por diseño,
`services/api_service.dart`). Ingresar:

```
https://<IP_LAN>/api/v1
```

`normalizeBaseUrl` agrega `/api/v1` si falta y tolera con/sin esquema y barra final.

### Atajo con QR (web)

Abrir la web **desde la IP LAN**: `https://<IP_LAN>/login`. El certificado generado
usa esa IP como CN y ya la incluye en el SAN, junto con `anomalia.local`, `localhost` y
`127.0.0.1`. El QR del login usa `window.location.origin`, así que codifica
`anomalia://config?base_url=https://<IP_LAN>`. Escanearlo en el celular → la app se
autoconfigura (deep link `anomalia://config`).

> El bloque **"Acceso desde app móvil"** está **colapsado por defecto**: hacer click para
> desplegar la URL y el QR. Si se abre la web como `https://anomalia.local`, el QR apuntará
> a ese FQDN; abrí siempre por IP para la prueba en el celular.

## 7. Probar SSO en el celular

El IdP de prueba se publica por defecto como `http://anomalia.local:8080`, que el celular
no resuelve. Para probar SSO hay que usar la **IP LAN** como issuer, de forma consistente
entre el navegador del celular y el backend.

1. Detener el IdP actual y levantarlo con el issuer en la IP LAN (script del repo
   [`anomalia-backend`](https://github.com/anomalia-io/anomalia-backend) → `scripts/oidc-test/run-test-idp.sh`):
   ```bash
   scripts/oidc-test/run-test-idp.sh --configure --groups viewer \
     --issuer http://<IP_LAN>:8080
   ```
   - `--issuer` (no `--port`) deja `issuer_url`/`discovery_url` en `<IP_LAN>`.
   - El puerto se publica en `0.0.0.0:8080`, así que el celular lo alcanza.
   - El backend (contenedor) debe poder llegar a `<IP_LAN>:8080` para discovery y
     token exchange.
2. Limpiar el provider anterior (`issuer_url=http://anomalia.local:8080`) para no dejar dos
   proveedores activos; `--configure` fija `default_oidc_provider_id` al nuevo.
3. Verificar que la redirect `anomalia://callback` esté permitida en el client del mock
   (está por defecto).
4. En el celular:
   - Configurar `https://<IP_LAN>/api/v1`.
   - Tocar **"Iniciar sesión con OIDC"** → se abre el navegador del celular.
   - Login: `test@anomalia.local` / `testpass`.
   - El IdP redirige a `anomalia://callback` → Android abre la app
     (intent-filter `anomalia://callback` en `android/app/src/main/AndroidManifest.xml`).
   - La app llama al backend → entrás a **Alertas**.

## 8. Resolución de problemas

- **No aparece el celular en `flutter devices`**: permisos USB/udev o cable "solo carga".
- **No conecta al backend**: firewall del host bloqueando `443` desde la LAN; verificar solo
  alcance con `curl -k https://<IP_LAN>/api/v1/settings/auth` desde otra máquina de la red
  (`-k` ignora la validación del certificado y no reemplaza confiar en la CA).
- **SSO abre el navegador pero no vuelve a la app**: el issuer debe ser la IP LAN (paso 7) y
  `anomalia://callback` debe estar en la allowlist del client.
- **Release no conecta**: TLS estricto; instalá y confiá la CA local en el celular. El proyecto
  no declara una configuración de red de Android adicional.

## 9. Referencias

- Flujo OIDC móvil: `specs/020-oidc-sso-integration.md`.
- App móvil: [flutter-app.md](flutter-app.md).
- IdP de prueba: `AGENTS.md` §2.6.
