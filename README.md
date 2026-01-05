# TVMax (Cliente No Oficial Atresplayer)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

Aplicación multiplataforma (**Android, iOS, Linux, macOS y Windows**) desarrollada como proyecto educativo para explorar las capacidades de Flutter en el desarrollo de aplicaciones móviles y de escritorio.

Este proyecto tiene como objetivo principal el aprendizaje de:
*   Arquitectura Limpia (Clean Architecture).
*   Consumo y gestión de APIs REST complejas.
*   Manejo avanzado de Streams y descargas en segundo plano.
*   Integración nativa (FFI) con reproductores de vídeo (VLC/MediaKit).

Diseñada para ser rápida, privada y funcional, ofreciendo una experiencia fluida sin coste adicional, utilizando tu propia cuenta o contenido gratuito.

---

## Roadmap

*   **Ecosistema Apple (iOS / macOS):**
    *   Actualmente se ofrecen binarios **sin firmar** (.app/.zip) generados automáticamente por GitHub Actions.
    *   Para instalarlos en dispositivos físicos, es necesario realizar el proceso de firma manual o utilizar herramientas como AltStore (iOS) o permitir la ejecución de apps sin firmar (macOS).

---

## Descargas (Versión v1.0)

Elige la versión adecuada para tu dispositivo:

| Plataforma | Archivo | Descripción | Enlace |
| :--- | :--- | :--- | :--- |
| **Android (Moderno)** | `tvmax-arm64-v8a-release.apk` | Para móviles actuales (últimos 5-6 años). Mayor rendimiento. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-arm64-v8a-release.apk) |
| **Android (Antiguo)** | `tvmax-armeabi-v7a-release.apk` | Para móviles antiguos o gama baja. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-armeabi-v7a-release.apk) |
| **Windows** | `tvmax-full-x64-setup.exe` | Instalador completo. Incluye dependencias necesarias. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-full-x64-setup.exe) |
| **Linux (Recomendado)**| `tvmax-full.AppImage` | Versión autónoma. Incluye ffmpeg y yt-dlp. Funciona en cualquier distribución. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-full.AppImage) |
| **Linux (Ligero)** | `tvmax-lite.AppImage` | Versión reducida (~18MB). Requiere tener ffmpeg instalado. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-lite.AppImage) |
| **macOS (Intel/M1)** | `tvmax-macos-unsigned.zip` | Binario (.app) sin firmar. | [Descargar](https://github.com/roberbarras/tvmax/actions/runs/20715785518/artifacts/5024390753) |
| **iOS (Experimental)** | `tvmax-ios-unsigned.zip` | App sin firmar (.app). Requiere firma manual. | [Descargar](https://github.com/roberbarras/tvmax/actions/runs/20715785518/artifacts/5024363506) |

---

## Características Principales

*   **Rendimiento Optimizado**:
    *   **Modo Eco**: Detecta automáticamente equipos con recursos limitados y ajusta la carga gráfica.
    *   **Gestión de Memoria**: Carga de imágenes optimizada para reducir el consumo de RAM.
*   **Descargas Inteligentes**:
    *   **Watchdog**: Sistema de recuperación automática de descargas interrumpidas o fallidas por inestabilidad de red.
    *   **Portabilidad**: Los vídeos se descargan en formato .mp4 estándar.
*   **Reproductor Híbrido**:
    *   Soporte para subtítulos y selección de calidad manual o automática.
    *   **Fallback Automático (Linux)**: Cambio automático a renderizado por software en caso de fallo de drivers gráficos.
*   **Gestión de Sesión**:
    *   Posibilidad de utilizar cuenta propia (Free o Premium) mediante inyección de cookie de sesión.

---

## Requisitos e Instalación

### Android
*   **Versión:** Android 7.0 o superior.
*   **Instalación:** Descarga e instala el archivo APK. Es posible que debas autorizar la instalación desde orígenes desconocidos.

### Windows
*   **Requisitos:** Windows 10/11 (64 bits).
*   **Instalación:** Ejecuta el instalador `setup.exe`. El asistente configurará todas las dependencias automáticamente.

### Linux
*   **Full (.AppImage)**:
    1.  Descarga el archivo.
    2.  Otorga permisos de ejecución: `chmod +x tvmax-full.AppImage`
    3.  Ejecuta el archivo.
*   **Lite (.AppImage)**:
    *   Requiere tener instalados `ffmpeg` y `python3` en el sistema (`sudo apt install ffmpeg python3` en Debian/Ubuntu).

### macOS
*   **Nota Importante:** Al no estar firmada con un certificado de desarrollador de Apple (requiere pago anual), el sistema bloqueará la ejecución por defecto ("Software malicioso no verificado").
*   **Instalación:**
    1.  Descomprime el archivo ZIP.
    2.  Arrastra la app a la carpeta Aplicaciones.
    3.  Al abrirla por primera vez, si muestra el error de seguridad, ve a **Preferencias del Sistema > Seguridad y Privacidad** y pulsa en "Abrir de todas formas".
    4.  Alternativamente, haz clic derecho sobre la app y selecciona **Abrir**, y confirma en el diálogo emergente.

### iOS
*   **Nota Importante:** Para instalar aplicaciones fuera de la App Store (.ipa/.app) es necesario firmarlas.
*   **Instalación (Sideloading):**
    *   **AltStore (Recomendado):** Utiliza AltServer en tu PC/Mac para instalar la app en tu iPhone/iPad (requiere renovar cada 7 días).
    *   **Certificado de Desarrollador:** Si dispones de uno, puedes firmar y desplegar la app usando Xcode o herramientas similares.

---

## Manual de Uso Rápido

### 1. Configuración Inicial
Para acceder a contenido restringido, es necesario configurar la Cookie de Sesión:
1.  Accede a la web oficial desde un navegador de escritorio.
2.  Inicia sesión con tus credenciales.
3.  Abre las Herramientas de Desarrollador (F12) y localiza la petición principal en la pestaña **Red**.
4.  Copia el valor del encabezado `Cookie`.
5.  En TVMax, ve a **Ajustes** y pega el valor en el campo correspondiente.
6.  Guarda y reinicia la aplicación.

### 2. Reproducción
*   **Calidad:** Icono HQ para selección manual (1080p, 720p, etc).
*   **Subtítulos:** Icono CC para activar/desactivar.

### 3. Descargas
*   Utiliza el botón de descarga en la ficha del episodio.
*   El sistema gestionará la descarga en segundo plano y recuperará errores automáticamente.

Para más detalles, consulta la **[Guía de Usuario (USER_GUIDE.md)](USER_GUIDE.md)**.

---

> **Aviso:** Este es un proyecto estrictamente educativo sin ánimo de lucro. La aplicación no aloja contenido ni elude sistemas de protección DRM. El usuario es responsable de utilizar sus propias credenciales de acceso legítimas.

---
Creado con Flutter.
