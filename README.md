# Retrovoz Challenge

**Graba tu voz, escúchala al revés y reta a tus amigos.**

Retrovoz Challenge es un juego para Android hecho en Flutter por **TicNoticos**. Ya está publicado en Google Play:
[com.blogspot.retrovoz](https://play.google.com/store/apps/details?id=com.blogspot.retrovoz).

---

## ¿Cómo se juega?

1. **Graba** una palabra o frase con el botón de micrófono.
   - **Mantén presionado** el botón y suéltalo para terminar (estilo walkie-talkie), o
   - **toca una vez** para empezar y vuelve a tocar para detener.
2. La app **invierte el audio** automáticamente.
3. **Escucha** la grabación original o la versión al revés.
4. **El reto:** un jugador graba la frase al revés, los demás intentan imitarla y la app vuelve a invertir esa imitación. ¿Se entiende la frase original?
5. Si te gusta un sonido, **guárdalo en Favoritos** para escucharlo más tarde.

---

## Funcionalidades

| Funcionalidad | Descripción |
|---|---|
| Grabación | WAV PCM sin compresión: 16 bits, 44,1 kHz, mono. Pide permiso de micrófono y, si está bloqueado, envía a los ajustes del sistema. |
| Inversión de audio | La hace la propia app, sin librerías externas ni servidores (ver más abajo). |
| Reproducción | Reproduce el audio original y el invertido con `just_audio`, junto a una onda animada. |
| Favoritos | Guarda los audios invertidos en SQLite y en una carpeta propia. Se conservan como máximo **20**: al guardar uno nuevo se borra el más antiguo. |
| Limpieza automática | Las grabaciones temporales de la sesión también se limitan a las **20** más recientes. |
| Tema claro / oscuro | Se guarda con `shared_preferences`. |
| Blog y ayuda | El menú lateral abre los artículos "Cómo jugar" y "Graba, invierte y juega" dentro de la app (WebView). |
| Compartir | El botón compartir en "Acerca de" envía el enlace de Play Store. |
| Anuncios (AdMob) | Un anuncio de apertura en la pantalla de carga, un banner adaptativo en el estudio y un intersticial opcional cada 7 a 13 reproducciones al revés. |

---

## Cómo se invierte el audio

Todo el trabajo está en [lib/core/services/audio_reverse_service.dart](lib/core/services/audio_reverse_service.dart) y corre en un **Isolate** (`compute`), para que la interfaz no se congele.

1. **Lee la cabecera RIFF/WAVE.** Recorre los chunks uno por uno, sin asumir una cabecera fija de 44 bytes, para encontrar `fmt ` y `data`.
2. **Valida el formato.** Solo acepta PCM lineal (formato 1). Si el archivo está cortado, ajusta el tamaño de los datos.
3. **Invierte los frames:** `y[n] = x[N − 1 − n]`. Se copia cada frame completo, de modo que no se mezclan los canales ni se altera el orden de los bytes de cada muestra.
4. **Escribe un WAV estándar** (cabecera de 44 bytes más los datos invertidos) en el directorio de documentos de la app.

---

## Arquitectura

El proyecto se organiza por *features* y sigue Clean Architecture. Las dependencias se crean en un contenedor sencillo ([injection_container.dart](lib/core/di/injection_container.dart)).

```
lib/
├── main.dart                     # Carga .env, inicia la inyección de dependencias y AdMob, y arranca la app
├── core/
│   ├── constants/                # Versión (leída de pubspec.yaml), URL de Play Store, IDs de AdMob
│   ├── di/                       # InjectionContainer
│   ├── routes/                   # AppRoutes y AppRouter
│   ├── services/
│   │   ├── audio_recording_service.dart   # Permisos y grabación (record)
│   │   ├── audio_reverse_service.dart     # Inversión del WAV
│   │   └── audio_player_service.dart      # Reproducción (just_audio)
│   ├── theme/                    # Colores, temas y ThemeController
│   └── utils/ads.dart            # Lectura de los IDs de anuncios desde .env
└── features/
    ├── loading/                  # Pantalla de carga animada y anuncio de apertura
    ├── home/                     # Inicio, estudio de grabación, menú, Acerca de, privacidad, blog
    ├── favorites/                # Base de datos SQLite, servicio y pantalla de favoritos
    └── ads/                      # Datos, dominio y casos de uso de AdMob
```

### Pantallas (`AppRoutes`)

| Ruta | Pantalla |
|---|---|
| `/` | Carga (`LoadingScreen`) |
| `/home` | Inicio (`HomeScreen`) |
| `/recording` | Estudio de grabación y reproducción (`RecordingScreen`) |
| `/favorites` | Favoritos (`FavoritesScreen`) |
| `/privacy-policy` | Política de privacidad |
| `/about` | Acerca de |

---

## Requisitos

- Flutter con Dart SDK `^3.11.4`
- Android `minSdk` 24 o superior
- Un dispositivo o emulador con micrófono

## Configuración

### 1. Variables de entorno (`.env`)

La app carga un archivo `.env` en la raíz del proyecto. Git lo ignora y está declarado como *asset*. **Si no existe, la app no arranca.**

```env
# IDs reales de AdMob (producción)
BANNER_AD_UNIT_ID=
OPEN_APP_AD_UNIT_ID=
INTERSTITIAL_AD_UNIT_ID=
REWARD_AD_UNIT_ID=

# Opcionales: IDs de prueba (si faltan, se usan los de prueba de Google)
BANNER_AD_UNIT_ID_TEST=
OPEN_APP_AD_UNIT_ID_TEST=
INTERSTITIAL_AD_UNIT_ID_TEST=
REWARD_AD_UNIT_ID_TEST=
```

> Durante el desarrollo conviene usar los IDs de prueba. Para eso, en [lib/core/utils/ads.dart](lib/core/utils/ads.dart) cambia `ReverAdsIds` para que use `ReverAdsIdsTest`. Así no se generan impresiones inválidas en la cuenta de AdMob.

El ID de la aplicación de AdMob está en `android/app/src/main/AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`).

### 2. Instalar y ejecutar

```bash
flutter pub get
flutter run
```

### 3. Pruebas

```bash
flutter test
```

| Archivo | Qué prueba |
|---|---|
| `audio_reverse_service_test.dart` | Lectura del WAV, inversión de frames y cabecera de salida |
| `favorites_service_test.dart` | Guardado, borrado y límite de 20 favoritos (con `sqflite_common_ffi`) |
| `loading_controller_test.dart` | Flujo de la pantalla de carga |
| `theme_controller_test.dart` | Cambio de tema y persistencia |
| `widget_test.dart` | Prueba básica de widgets |

---

## Publicación

- **Versión:** se cambia solo en `pubspec.yaml` (`version: x.y.z+build`). La app la lee en tiempo de ejecución, así que lo que muestra "Acerca de" siempre coincide.
- **Ícono:** se genera con `flutter_launcher_icons` a partir de `assets/logo_actual.png` y los recursos adaptativos:
  ```bash
  dart run flutter_launcher_icons
  ```
- **Build para Play Store:**
  ```bash
  flutter build appbundle --release
  ```
  Antes de compilar, revisa que `.env` tenga los IDs **reales** de AdMob.

---

## Dependencias principales

`record` · `just_audio` · `permission_handler` · `path_provider` · `sqflite` · `google_mobile_ads` · `flutter_dotenv` · `webview_flutter` · `shared_preferences` · `share_plus` · `google_fonts` · `percent_indicator`

---

© TicNoticos. Retrovoz Challenge.
