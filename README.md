# 🌅 Sunset Diary — Diario de atardeceres

Aplicación móvil desarrollada en **Flutter y Dart** para la asignatura **Programación para Dispositivos Móviles — Parcial 2**.

## Problema que resuelve

Muchas veces capturamos fotografías de atardeceres y, con el tiempo, olvidamos dónde las tomamos o qué hacía especial ese momento.

**Sunset Diary** es un diario personal que permite guardar y recordar atardeceres mediante fotografías, descripciones, fechas y ubicaciones geográficas, conservando esos momentos especiales en una galería accesible desde el dispositivo móvil.

## Funcionalidades

- **Galería de atardeceres:** visualización de recuerdos organizados por fecha.
- **Cámara y galería:** captura de fotografías o selección de imágenes existentes mediante `image_picker`.
- **Dictado por voz:** conversión de voz a texto para describir recuerdos mediante `speech_to_text`.
- **Geolocalización GPS:** captura de coordenadas mediante `geolocator`.
- **Google Maps:** consulta de la ubicación registrada mediante `url_launcher`.
- **Persistencia local:** almacenamiento de registros con SQLite (`sqflite`) y fotografías en el directorio de la aplicación.
- **Gestión de recuerdos:** registro, consulta, reemplazo de fotografías y eliminación.
- **Autenticación local:** acceso protegido mediante `local_auth`, compatible con Face ID y los métodos de autenticación permitidos por iOS.

## Arquitectura por capas

```text
lib/
├── main.dart
├── models/
│   └── sunset.dart
├── services/
│   └── database_service.dart
└── screens/
    ├── auth_screen.dart
    ├── home_screen.dart
    ├── add_sunset_screen.dart
    └── detail_screen.dart
```

El proyecto está organizado en tres responsabilidades principales:

- **Modelo:** `Sunset` representa los registros y permite su conversión para SQLite.
- **Servicio:** `DatabaseService` administra la base de datos y el almacenamiento de fotografías.
- **Presentación:** las pantallas gestionan la navegación, los formularios y las interacciones con el usuario.

Esta separación facilita el mantenimiento del código y aplica el principio de responsabilidad única en las principales clases.

## Navegación e interfaz

La aplicación utiliza `Scaffold`, `AppBar`, `Drawer`, rutas nombradas y `Navigator` para navegar entre sus pantallas.

Incorpora animaciones `Hero` entre la galería y los detalles, junto con una interfaz basada en Material 3 y colores inspirados en los atardeceres.

## Almacenamiento y manejo de errores

Los registros se almacenan localmente mediante SQLite, mientras que las fotografías se conservan en el directorio de documentos de la aplicación.

Se utiliza `FutureBuilder` para cargar los registros de forma asíncrona y mostrar los estados de carga, error, galería vacía y resultados.

Las operaciones de cámara, micrófono, GPS y almacenamiento incorporan manejo de excepciones mediante `try-catch` y mensajes informativos.

## Tecnologías utilizadas

- Flutter y Dart
- `sqflite`, `path` y `path_provider`
- `image_picker`
- `speech_to_text`
- `geolocator`
- `url_launcher`
- `local_auth`
- `intl`

## Cómo ejecutar

**1.** Instalar Flutter y configurar un dispositivo compatible.

**2.** Clonar el repositorio y abrir la carpeta del proyecto.

**3.** Descargar las dependencias:

```bash
flutter pub get
```

**4.** Verificar los dispositivos disponibles:

```bash
flutter devices
```

**5.** Ejecutar la aplicación:

```bash
flutter run
```

Si hay varios dispositivos disponibles, se puede indicar uno específico:

```bash
flutter run -d <ID_DEL_DISPOSITIVO>
```

Para ejecutar en un iPhone físico se requiere macOS, Xcode configurado y firma de desarrollo. La conexión puede realizarse mediante USB o de forma inalámbrica, siempre que el dispositivo esté emparejado correctamente.

**Nota:** Los recuerdos se almacenan localmente en el dispositivo. Desinstalar la aplicación puede eliminar los registros y fotografías guardados.

## Autor

**Isaac Padilla**  
Ingeniería en Tecnologías de la Información y Negocios Digitales  
Universidad Anáhuac Mayab