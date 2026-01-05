# TVMax (Unofficial Atresplayer Client)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

Aplicación multiplataforma (**Android, iOS, Linux, macOS y Windows**) desarrollada como proyecto **educativo** para explorar las capacidades de **Flutter** en el desarrollo de aplicaciones móviles y de escritorio.

Este proyecto tiene como objetivo principal el **aprendizaje**:
*   Arquitectura Limpia (Clean Architecture) en Flutter 3.
*   Consumo y gestión de APIs REST complejas.
*   Manejo avanzado de Streams y descargas en segundo plano.
*   Integración nativa (FFI) con reproductores de vídeo (VLC/MediaKit).

Diseñada para ser rápida, privada y funcional, ofreciendo una experiencia premium sin coste adicional (usando tu propia cuenta o contenido gratuito).

---

---

## 🗺️ Roadmap (Próximamente)

*   **🍎 Apple Ecosystem (iOS / macOS):**
    *   La base de código de Flutter ya es compatible con iOS y macOS.
    *   Sin embargo, **actualmente no dispongo de la infraestructura de hardware necesaria (Mac) para compilar y firmar los binarios**.
    *   En cuanto sea posible, se añadirán los ejecutables `.ipa` y `.dmg` a las Releases.

---

## 📥 Descargas (Última Versión v1.0)

Elige la versión adecuada para tu dispositivo:

| Plataforma | Archivo | Descripción | Enlace |
| :--- | :--- | :--- | :--- |
| **Android (Moderno)** | `tvmax-arm64-v8a-release.apk` | Para móviles actuales (últimos 5-6 años). Mayor rendimiento. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-arm64-v8a-release.apk) |
| **Android (Antiguo)** | `tvmax-armeabi-v7a-release.apk` | Para móviles antiguos o gama baja. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-armeabi-v7a-release.apk) |
| **Windows** | `tvmax-full-x64-setup.exe` | Instalador completo. Incluye todo lo necesario (no requiere configurar nada). | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-full-x64-setup.exe) |
| **Linux (Recomendado)**| `tvmax-full.AppImage` | Versión autónoma. Incluye `ffmpeg` y `yt-dlp`. Funciona en cualquier distro. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-full.AppImage) |
| **Linux (Ligero)** | `tvmax-lite.AppImage` | Versión reducida (~18MB). Requiere que tengas `ffmpeg` instalado en tu sistema. | [Descargar](https://github.com/roberbarras/tvmax/releases/download/1.0/tvmax-lite.AppImage) |

---

## ✨ Características Principales

*   **⚡ Rendimiento Optimizado**:
    *   **Modo Eco**: Detecta automáticamente PCs lentos (antiguos) y ajusta la velocidad de carga para evitar bloqueos.
    *   **Gestión de Memoria**: Carga de imágenes optimizada para consumir un 70% menos de RAM en listas grandes.
*   **⬇️ Descargas Inteligentes**:
    *   **Watchdog**: Si una descarga se queda "pegada" (común en redes inestables), la app la detecta y reinicia automáticamente sin que tengas que hacer nada.
    *   **Portabilidad**: Los vídeos se descargan en formato `.mp4` compatible con cualquier reproductor.
*   **🎮 Reproductor Híbrido**:
    *   Soporte para subtítulos y selección de calidad (1080p, 720p...).
    *   **Fallback Automático (Linux)**: Si tu tarjeta gráfica falla (pantallazo azul), el reproductor cambia solo a modo software para no crashear.
*   **🍪 Gestión de Sesión**:
    *   Usa tu propia cuenta (Free o Premium) copiando tu cookie de sesión.

---

## 🛠️ Requisitos e Instalación

### Android
*   **Versión:** Android 7.0 o superior.
*   **Instalación:** Descarga el APK, abre el archivo y acepta "Instalar aplicaciones desconocidas" si se te solicita.

### Windows
*   **Requisitos:** Windows 10/11 (64 bits).
*   **Instalación:** Ejecuta el instalador `setup.exe`. El programa se encargará de configurar las herramientas de descarga (`yt-dlp`) automáticamente.

### Linux
*   **Full (`.AppImage`)**:
    1.  Descarga el archivo.
    2.  Dale permisos de ejecución: `chmod +x tvmax-full.AppImage`
    3.  Ejecuta con doble clic.
*   **Lite (`.AppImage`)**:
    *   Igual que el anterior, pero asegúrate de tener instalado: `sudo apt install ffmpeg python3`

---

---

## 📖 Manual de Uso Rápido

### 1. Configuración Inicial (¡Importante!)
Para ver contenido Premium, necesitas tu **Cookie de Sesión**:
1.  Ve a **Ajustes** dentro de la App.
2.  Pega el valor de la cookie `Cookie` de atresplayer.com (puedes obtenerla desde las herramientas de desarrollador de tu navegador, F12 -> Red).
3.  Guarda y reinicia.

### 2. Reproducción
*   **Calidad:** Pulsa el icono **HQ** para cambiar entre 1080p, 720p, etc.
*   **Subtítulos:** Pulsa **CC** para activarlos.
*   **Problemas:** Si en Linux ves una pantalla azul, espera 2 segundos. La app cambiará sola a "Modo Seguro".

### 3. Descargas
*   Pulsa el botón de descarga en cualquier episodio.
*   Si la descarga se detiene, el sistema la reanudará automáticamente.

ℹ️ **[Ver Guía de Usuario Completa (USER_GUIDE.md)](USER_GUIDE.md)** para detalles avanzados y solución de problemas.

---

> [!NOTE]
> **Proyecto Educativo:** Esta aplicación no tiene relación oficial con Atresmedia. Se ha creado únicamente para demostrar cómo estructurar una aplicación moderna en Flutter que interactúa con servicios web reales de alta demanda.

---
*Hecho con ❤️ y Flutter.*
