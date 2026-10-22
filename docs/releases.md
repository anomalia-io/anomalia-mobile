# Releases y APK

Las versiones de la app se publican como **GitHub Releases** en
[`anomalia-mobile/releases`](https://github.com/anomalia-io/anomalia-mobile/releases).

## Descargar el APK

1. Entrá a [Releases](https://github.com/anomalia-io/anomalia-mobile/releases) y elegí la última.
2. Descargá `app-release.apk` y `checksums.txt`.
3. Verificá la integridad:

   ```bash
   sha256sum -c checksums.txt
   ```

4. Instalá el APK en el celular (permití "instalar apps de origen desconocido" si hace falta).

> La app arranca sin servidor configurado: ingresá la URL de tu gateway (o escaneá el QR de la
> consola web) en la pantalla de configuración.

## Verificar la firma

Cada APK release está firmado con la clave de distribución del proyecto. Para inspeccionar el
certificado:

```bash
# Requiere Android SDK build-tools
apksigner verify --print-certs app-release.apk
```

El fingerprint SHA-256 del certificado se publica aquí para que puedas compararlo:

```
SHA-256: <pendiente de publicar en el primer release>
```

## Compilar tu propio APK

Si preferís auditar el código y compilar vos mismo (no requiere keystore propio):

```bash
flutter pub get
flutter build apk --release
# salida: build/app/outputs/flutter-apk/app-release.apk
```

Para builds de desarrollo/pruebas:

```bash
flutter build apk --debug
```

Guía de instalación y prueba en un celular real: [testing-on-device.md](testing-on-device.md).

## Publicar un release (mantenedor)

El workflow `.github/workflows/release.yml` se dispara al pushear un tag `v*`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Requiere los secrets `RELEASE_KEYSTORE` (base64 del `.jks`), `RELEASE_STORE_PASSWORD`,
`RELEASE_KEY_PASSWORD` y `RELEASE_KEY_ALIAS`. El workflow compila el APK firmado, genera
`checksums.txt` y crea el Release con `--generate-notes`.
