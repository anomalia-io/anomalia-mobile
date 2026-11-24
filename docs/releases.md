# Releases y APK

Las versiones de Android se publican como **GitHub Releases** en
[`anomalia-mobile/releases`](https://github.com/anomalia-io/anomalia-mobile/releases).

## Descargar el APK

1. Entrá a [Releases](https://github.com/anomalia-io/anomalia-mobile/releases) y elegí la última.
2. Descargá `anomalia.apk` y `checksums.txt`.
3. Verificá la integridad:

   ```bash
   sha256sum -c checksums.txt
   ```

4. Instalá el APK en el celular (permití "instalar apps de origen desconocido" si hace falta).

> La app arranca sin servidor configurado: ingresá la URL de tu gateway (o escaneá el QR de la
> consola web) en la pantalla de configuración. En el celular usá la IP LAN del gateway (o el
> hostname provisto con `--hostname`), no `anomalia.local` salvo que resuelva en tu red, y confiá
> la CA local si el build es release.

## Limitación de firma

El workflow `.github/workflows/release.yml` genera un keystore y `android/key.properties`, pero
`android/app/build.gradle.kts` todavía usa `signingConfigs.getByName("debug")` para el tipo
`release`. Por eso el APK publicado como `anomalia.apk` **no debe considerarse firmado con una
clave de distribución**. No hay un fingerprint de release confiable publicado todavía.

Para inspeccionar lo que realmente trae el artefacto:

```bash
# Requiere Android SDK build-tools
apksigner verify --print-certs anomalia.apk
```

## Compilar tu propio APK

Toolchain: Flutter 3.47.2, Dart `^3.13.2`.

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test --dart-define=FLUTTER_TEST=true
flutter build apk --release
# salida: build/app/outputs/flutter-apk/app-release.apk
```

Para builds de desarrollo/pruebas:

```bash
flutter build apk --debug
```

No hay flujo de `flutter build ios --release`: iOS no tiene `GoogleService-Info.plist` ni setup de
Firebase, y no está listo para producción.

Guía de instalación y prueba en un celular real: [testing-on-device.md](testing-on-device.md).

## Publicar un release (mantenedor)

El workflow `.github/workflows/release.yml` se dispara al pushear un tag `v*`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

El workflow espera los secrets `RELEASE_KEYSTORE` (base64 del `.jks`), `RELEASE_STORE_PASSWORD`,
`RELEASE_KEY_PASSWORD` y `RELEASE_KEY_ALIAS`, compila, renombra el artefacto a `anomalia.apk`,
genera `checksums.txt` y crea el Release con `--generate-notes`. Hasta que el Gradle consuma la
configuración de firma de release, la advertencia de la sección anterior sigue aplicando.
