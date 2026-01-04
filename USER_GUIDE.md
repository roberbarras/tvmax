# 📺 TVMax - Guía de Usuario Completa

Bienvenido a **TVMax**, tu cliente de escritorio y móvil para disfrutar de contenido de Atresplayer sin restricciones. Esta guía te ayudará a instalar, configurar y sacar el máximo partido a la aplicación en cualquier dispositivo.

---

## 🚀 Características Destacadas

*   **Multiplataforma:** Disponible de forma nativa en **Windows**, **Linux** y **Android**.
*   **Descargas Inteligentes:** Descarga tus series y programas favoritos para verlos sin conexión. Incluye un sistema "Watchdog" que reintenta automáticamente si la descarga se queda pegada.
*   **Reproductor Avanzado:**
    *   Soporte para subtítulos y cambio de calidad (1080p, 720p, etc.).
    *   **Fallback Dinámico:** Detecta si tu hardware gráfico falla (pantallazo azul en Linux) y cambia automáticamente a modo seguro.
*   **Favoritos:** Marca tus contenidos preferidos para tenerlos siempre a mano al inicio.
*   **Privado:** Tus datos se quedan en tu dispositivo.

---

## 📦 Instalación y Requisitos

### 1. 🤖 Android
*   **Requisitos:** Android 7.0 o superior.
*   **Instalación:**
    1.  Descarga el archivo `.apk` correspondiente a tu arquitectura (normalmente `arm64-v8a` para móviles modernos).
    2.  Abre el archivo y acepta la instalación de orígenes desconocidos si se te pide.
*   **Permisos:** La primera vez que intentes descargar, te pedirá permiso para mostrar notificaciones. Acéptalo para ver el progreso de tus descargas.

### 2. 🐧 Linux
*   **Formato:** Usamos **AppImage**, un formato portable que funciona en casi cualquier distribución (Ubuntu, Fedora, Arch...).
*   **Instalación:**
    1.  Descarga el archivo `TVMax.AppImage`.
    2.  Hazlo ejecutable: `Right Click -> Properties -> Permissions -> Allow executing file as program` (o `chmod +x TVMax.AppImage`).
    3.  Haz doble clic para abrir.
*   **Nota:** La aplicación ya incluye dentro las herramientas `ffmpeg` y `yt-dlp` necesarias.

### 3. 🪟 Windows
*   **Formatos:**
    *   **Instaldor (`setup_tvmax.exe`):** La opción recomendada. Instala el programa y crea accesos directos.
    *   **Portable (`.zip`):** Si prefieres no instalar nada.
*   **Nota Importante:** El instalador ya configuran todo automáticamente.

---

## ⚙️ Configuración Inicial (Crítico)

Para poder acceder a los contenidos protegidos, necesitas configurar tu sesión.

1.  Abre la aplicación y ve a la pestaña **Ajustes** (icono de engranaje).
2.  Busca la sección **Autenticación (Cookies)**.
3.  Debes pegar aquí el valor de tu cookie de sesión.
    *   *Cómo obtenerla:* Inicia sesión en la web oficial desde tu navegador, abre las Herramientas de Desarrollador (F12) -> Red/Network, haz clic en cualquier petición y busca la cabecera `Cookie` en la solicitud. Copia todo el valor.
4.  Pulsa **Guardar**.
5.  Reinicia la aplicación para asegurarte de que carga tu perfil (Premium/Free).

---

## 🎮 Guía de Uso

### Reproducción de Vídeo
*   **Calidad:** Al reproducir, pulsa el icono **HQ** para seleccionar manualmente la resolución (1080p, 720p, 480p) o dejarlo en Automático.
*   **Subtítulos:** Pulsa el icono **CC** para activar/desactivar subtítulos o cambiar el idioma.
*   **Preferencias por Defecto:** En *Ajustes*, puedes definir si quieres que los vídeos empiecen siempre con o sin subtítulos, y en qué calidad predeterminada.

### Descargas
1.  Abre cualquier episodio o programa.
2.  Pulsa el botón de **Descargar**.
3.  Verás el progreso en la pantalla y en las notificaciones del sistema.
4.  Si la descarga se congela por más de 60 segundos, el sistema la reiniciará automáticamente.
5.  **Ubicación:** Por defecto se guardan en tu carpeta `Descargas` (o `Documents` en Android), pero puedes cambiar la ruta en *Ajustes*.

---

## 🛠️ Solución de Problemas (Troubleshooting)

### 🔹 Pantalla Azul al reproducir video (Linux)
*   **Causa:** Tu tarjeta gráfica o drivers no soportan la aceleración por hardware que intentamos usar.
*   **Solución Automática:** La aplicación detectará el error (`GLSL not supported`), mostrará un aviso en los logs y **reiniciará el reproductor en modo Software** automáticamente. No tienes que hacer nada, solo esperar un segundo.

### 🔹 Las descargas fallan en Windows (Modo Debug)
*   Si estás desarrollando o ejecutando una versión "debug" (`flutter run`), es posible que te falten los binarios `yt-dlp.exe` y `ffmpeg.exe`.
*   **Solución:** Descárgalos y colócalos en la carpeta `windows/bin/` dentro del proyecto.

### 🔹 No veo mis favoritos al inicio
*   La aplicación intenta cargar tus favoritos nada más abrir. Si no salen, prueba a pulsar en otra pestaña y volver a la principal para refrescar la lista.

### 🔹 La aplicación va lenta en mi PC antiguo
*   Hemos implementado un **Paralelismo Dinámico**. La app detecta cuántos núcleos tiene tu CPU y ajusta la velocidad:
    *   < 4 Núcleos: Modo lento (1 petición a la vez) para no colgar el PC.
    *   4+ Núcleos: Modo rápido (Múltiples peticiones paralelas).

---

**Licencia:** Open Source. Disfruta y contribuye.
