# Rumbo — app móvil

App Flutter para jóvenes que buscan su primera oportunidad laboral: check-in de
bienestar, vacantes, revisión de CV con IA, práctica de entrevistas por voz,
mentoría individual y grupal, e insignias.

Es una de las tres superficies del proyecto Rumbo (HACKBIZ 2026, U.A.G.R.M.),
junto con el panel web y el backend FastAPI.

---

## Qué hay de nuevo en la 2.0.0

Rediseño completo de la interfaz sobre la identidad de marca, sin cambiar de
framework: sigue siendo Flutter, con Material 3.

**Paleta**

| Token | Color | Uso |
|---|---|---|
| Tinta | `#1F1F1F` | Fondo de toda la app |
| Carmín | `#A51C30` | Acción principal: botones, pestaña activa, foco |
| Marino | `#293352` | Color de apoyo: cabeceras, avatares, chips |

El tema es oscuro de punta a punta y vive en [`lib/theme.dart`](lib/theme.dart),
junto con las curvas y duraciones de animación (`RumboMotion`) y los radios
(`RumboRadii`). El carmín y el marino puros son demasiado oscuros para texto
sobre `#1F1F1F`, así que hay versiones aclaradas (`crimsonBright`, `navyBright`)
que se usan solo donde hace falta contraste.

**Interacción y fluidez**

- Entrada escalonada de listas y tarjetas (`FadeSlideIn`).
- Micro-interacción de pulsado en todo lo tocable (`PressableScale`) con háptica.
- Esqueletos de carga con la forma del contenido real, en lugar de un spinner.
- Barra inferior propia: la etiqueta se expande solo en la pestaña activa, así
  los cinco destinos entran cómodos en pantallas angostas.
- Transición de ruta compartida (`RumboPageRoute`) y `Hero` del título de la
  vacante hacia su detalle.
- Contadores que animan desde cero, barras de progreso que crecen al aparecer.
- Filtros de vacantes por chips en vez de desplegables.
- En la práctica de entrevista: transcripción en vivo de lo que oye el
  micrófono, y el avatar de la IA distingue hablar / escuchar / pensar.

**Arreglos que la app necesitaba para poder distribuirse**

- **Permiso de INTERNET en el manifest principal.** Solo estaba en los manifests
  de `debug` y `profile`, que genera Flutter para el hot reload. Un APK de
  release no podía llamar al backend: todas las pantallas fallaban.
- **Tráfico HTTP en claro.** Android 9+ lo bloquea por defecto. El backend corre
  por HTTP en la red local, así que se agregó
  [`network_security_config.xml`](android/app/src/main/res/xml/network_security_config.xml).
- **Dirección del servidor configurable.** Estaba fija en el código
  (`192.168.100.252:8001`), lo que obligaba a recompilar al cambiar de red y
  dejaba inservible cualquier APK compartido. Ahora se edita desde la app
  (icono de servidor en el login, o Perfil → Ajustes), se guarda en el
  dispositivo y tiene un botón para probar la conexión antes de guardar.
- **Firma de release propia** en lugar de la clave de debug.
- **Icono a sangre.** El original tenía un margen blanco que dejaba un anillo
  alrededor del logo; ahora se recorta y se genera además el icono adaptativo
  de Android.

---

## Requisitos

- Flutter 3.47+ (Dart 3.13+)
- Android SDK con platform 36
- El backend [`rumbo-backend`](https://github.com/Arlin-Ab/rumbo-backend) corriendo

## Correr en desarrollo

```bash
flutter pub get
flutter run
```

La primera vez, abrí el icono de servidor en la pantalla de login y apuntá la
app a tu backend:

| Dónde corre la app | Dirección |
|---|---|
| Emulador de Android | `http://10.0.2.2:8000` |
| Celular por Wi-Fi | `http://<IP-de-la-laptop>:8000` |
| Celular por USB | `http://localhost:8000` tras `adb reverse tcp:8000 tcp:8000` |

El puerto depende de cómo levantes el backend: `8000` con uvicorn directo,
`8001` con el `docker-compose` del repo del backend.

## Compilar el APK

```bash
flutter build apk --release
```

Queda en `build/app/outputs/flutter-apk/app-release.apk`.

La firma se toma de `android/key.properties`, que **no está en el repo** por
contener las contraseñas del keystore. Si el archivo no existe, el build cae a
la clave de debug y funciona igual para pruebas. Para publicar actualizaciones
que Android acepte instalar encima de una versión previa hay que usar siempre el
mismo keystore, así que conviene guardarlo (y sus contraseñas) donde el equipo
no lo pierda.

`android/key.properties` tiene esta forma:

```properties
storePassword=...
keyPassword=...
keyAlias=rumbo
storeFile=rumbo-release.jks
```

---

## Estructura

```
lib/
  main.dart                  # arranque, providers y splash
  theme.dart                 # paleta, tipografía, motion, transición de rutas
  config.dart                # URL del backend (persistida en el dispositivo)
  app_constants.dart         # áreas, países y niveles (mismo vocabulario que el backend)
  models/                    # modelos de la API
  services/
    api_client.dart          # cliente HTTP del backend FastAPI
    auth_controller.dart     # sesión (token JWT en SharedPreferences)
  utils/formato.dart         # formateo de fechas compartido
  widgets/
    ui_kit.dart              # piezas compartidas del sistema de diseño
    server_sheet.dart        # configurar y probar el servidor
    vacante_card.dart, feedback_view.dart, ai_avatar.dart
  screens/                   # una pantalla por caso de uso
```

## Roles

- `joven` — check-in, vacantes, recomendadas, CV, entrevistas, mentoría, insignias.
- `mentor` — perfil público, solicitudes, chat y sesiones grupales.

La pestaña *Crecimiento* cambia sus opciones según el rol de la cuenta.
