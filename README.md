# TVMax Desktop

Aplicación de escritorio multiplataforma (Linux, Windows, macOS) para navegar y reproducir contenido de tv de forma fluida y sin publicidad intrusiva. Desarrollada con Flutter y siguiendo principios de Clean Architecture y SOLID.

> [!WARNING]
> Esta es una aplicación no oficial y con fines educativos. Requiere una cuenta de Atresplayer (las cookies se configuran manualmente por ahora).

## Características

- 📺 **Navegación de Programas**: Explora el catálogo de programas disponibles.
- 🎬 **Listado de Episodios**: Visualiza episodios con imágenes y descripciones.
- ▶️ **Reproducción con VLC**: Integración directa con VLC Media Player para una experiencia de reproducción superior.
- ⬇️ **Descargas con yt-dlp**: Descarga tus episodios favoritos para verlos offline.
- 💾 **Modo Offline**: Cacheo automático de programas y episodios usando SQLite.
- 🎨 **Interfaz Moderna**: Diseño limpio y oscuro.

## Requisitos del Sistema

Para que la aplicación funcione correctamente, necesitas tener instaladas las siguientes herramientas en tu sistema:

1.  **VLC Media Player**: Para reproducir los vídeos.
    - Linux: `sudo apt install vlc` (Debian/Ubuntu) o `sudo pacman -S vlc` (Arch)
    - Windows: [Descargar VLC](https://www.videolan.org/)
    - macOS: `brew install --cask vlc`

2.  **yt-dlp**: Para la funcionalidad de descarga.
    - Linux: `sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && sudo chmod a+rx /usr/local/bin/yt-dlp`
    - Windows: [Descargar yt-dlp.exe](https://github.com/yt-dlp/yt-dlp) y añadir al PATH.
    - macOS: `brew install yt-dlp`

## Instalación y Ejecución

Sigue las instrucciones específicas para tu sistema operativo en el archivo [USER_GUIDE.md](USER_GUIDE.md).

### Ejecución Rápida (Desarrolladores)
1.  Asegúrate de tener Flutter instalado.
2.  Clona el repositorio.
3.  Instala dependencias:
    ```bash
    flutter pub get
    ```
4.  Ejecuta la app:
    ```bash
    flutter run -d linux # o windows/macos
    ```

## Arquitectura y Diseño Técnico

Este proyecto sigue una **Clean Architecture** estricta para asegurar escalabilidad, testabilidad y mantenimiento.

### Estructura de Directorios

```
lib/
├── core/                   # Componentes compartidos
│   ├── database/           # Configuración de SQLite
│   ├── error/              # Definición de fallos y excepciones
│   ├── usecases/           # Interfaz base para casos de uso
│   └── utils/              # Constantes y utilidades
├── features/               # Módulos funcionales
│   ├── episodes/           # Feature de Episodios
│   ├── player/             # Feature de Reproducción/Descarga
│   └── programs/           # Feature de Programas
│       ├── data/           # Capa de Datos (Repositorios, DataSources, Modelos)
│       ├── domain/         # Capa de Dominio (Entidades, Repositorios, Casos de Uso)
│       └── presentation/   # Capa de UI (Widgets, Pages, Providers)
├── injection_container.dart # Inyección de Dependencias (Service Locator)
└── main.dart               # Punto de entrada
```

### Decisiones de Diseño y Trade-offs

1.  **State Management (Provider)**:
    - *Decisión*: Se eligió `Provider` sobre opciones más complejas como BLoC/Riverpod por su simplicidad y efectividad para este alcance.
    - *Trade-off*: Menos boilerplate que BLoC, pero requiere disciplina para no mezclar lógica de UI en los Providers.

2.  **Clean Architecture**:
    - *Decisión*: Separación estricta en Domain, Data y Presentation.
    - *Beneficio*: Permite cambiar la fuente de datos (ej. de API a Mock o Local) sin tocar la UI. Facilita los tests unitarios.
    - *Costo*: Mayor número de archivos y clases (boilerplate) para funcionalidades simples.

3.  **Persistencia (SQLite con sqflite_common_ffi)**:
    - *Decisión*: Uso de FFI para soporte de escritorio nativo de SQLite.
    - *Estrategia*: **Network-First**. Se intenta obtener datos frescos de la API. Si falla, se recurre a la base de datos local mostrada como "Offline Mode".
    - *Trade-off*: La interfaz puede tardar un poco más en cargar inicialmente que una estrategia "Cache-First", pero asegura datos actualizados.

4.  **Integración Externa (Process.start)**:
    - *Decisión*: Invocar binarios de sistema (`vlc`, `yt-dlp`) en lugar de embeber reproductores complejos en Flutter.
    - *Beneficio*: Aprovecha la robustez de VLC y yt-dlp sin reinventar la rueda. Reduce el tamaño de la app.
    - *Costo*: Dependencia fuerte de que el usuario tenga estas herramientas instaladas.

## Tecnologías Utilizadas

- **Flutter & Dart**: Framework UI y lenguaje.
- **Provider**: Gestión de estado.
- **Dartz**: Programación funcional (Either) para manejo de errores.
- **GetIt**: Inyección de dependencias.
- **Sqflite FFI**: Base de datos local.
- **Http**: Cliente REST.
- **CachedNetworkImage**: Caché de imágenes eficiente.

## Contribución

Las Pull Requests son bienvenidas. Por favor, asegúrate de seguir los principios SOLID y mantener la cobertura de tests al añadir nuevas funcionalidades.
