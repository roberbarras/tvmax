# 📺 TVMax - Manual de Usuario Avanzado

Este manual detalla todas las funcionalidades, configuración y solución de problemas para **TVMax**.

---

## 1. 🚀 Introducción

TVMax es un cliente no oficial de código abierto para la plataforma Atresplayer. Su objetivo es ofrecer una experiencia **rápida**, **sin publicidad** y **privada**, permitiendo descargar contenido para verlo offline en cualquier lugar.

---

## 2. 📦 Instalación

### 🤖 Android (Móviles y Tablets)
*   **Android 7.0+** requerido.
*   **Arquitecturas:**
    *   **ARM64 (`v8a`)**: Para el 99% de móviles modernos (últimos 5 años). Mejor rendimiento.
    *   **ARMv7**: Para dispositivos antiguos o tabletas de gama baja.
*   **Pasos:** Descarga el APK -> Pulsa "Instalar" -> Acepta "Orígenes Desconocidos".

### 🐧 Linux (Todas las Distros)
*   Formato **AppImage** (Portable).
*   **Variantes:**
    1.  **Full (Recomendado):** Incluye todas las dependencias (`ffmpeg`, `yt-dlp`). Pesa ~100MB pero funciona siempre.
    2.  **Lite:** Pesa ~18MB. Solo úsala si ya tienes `ffmpeg` y `python3` instalados en tu sistema.
*   **Ejecución:** Dale clic derecho -> Propiedades -> Permisos -> "Permitir ejecutar como programa".

### 🪟 Windows (10/11)
*   Usa el instalador **`setup.exe`**.
*   El instalador configura automáticamente las rutas y dependencias necesarias. No hace falta instalar Python ni nada extra.

---

## 3. ⚙️ Configuración Vital (Cookies)

Para acceder a capítulos completos, contenido Premium o evitar restricciones geográficas, debes usar tu propia cuenta.

1.  **Obten tu Cookie:**
    *   Entra en [atresplayer.com](https://www.atresplayer.com) desde tu navegador (Chrome/Firefox).
    *   Inicia sesión con tu cuenta (Gratuita o Premium).
    *   Pulsa `F12` para abrir las Herramientas de Desarrollador.
    *   Ve a la pestaña **Red (Network)**.
    *   Recarga la página.
    *   Haz clic en la primera petición (normalmente `www.atresplayer.com`).
    *   A la derecha, en "Encabezados de Solicitud" (Request Headers), busca `Cookie`.
    *   **Copia todo el valor** de esa línea.

2.  **En la App:**
    *   Ve a **Ajustes** (icono engranaje).
    *   Pega el valor en el campo **"Cookie de Sesión"**.
    *   Pulsa **Guardar**.
    *   **Reinicia la app.**

> [!TIP]
> Si tu cuenta es Premium, verás el logotipo "Premium" en tu perfil dentro de la app y podrás descargar contenidos exclusivos.

---

## 4. 🎮 Uso de la Aplicación

### 🔍 Navegación y Búsqueda
*   **Barra Inferior:** Navega entre *Programas*, *Series*, *Documentales*, *Noticias*, *Favoritos* y *Ajustes*.
*   **Buscador Global:** (Próximamente) Por ahora explora por categorías alfabéticamente.
*   **Favoritos:** Pulsa el icono del corazón ❤️ en cualquier ficha para añadir la serie a tu lista rápida.

### ▶️ Reproductor Multi-Formato
*   **Calidad de Vídeo:**
    *   Pulsa **HQ** para elegir entre `1080p`, `720p`, `480p` o `Auto`.
    *   *Nota:* En conexiones lentas, elige 480p para evitar parones.
*   **Subtítulos:**
    *   Pulsa **CC** para activarlos.
    *   Desde *Ajustes*, puedes definir "Activar subtítulos por defecto".
*   **Controles:** Doble toque a los lados para avanzar/retroceder 10 segundos.

### ⬇️ Gestor de Descargas "Watchdog"
TVMax incluye un motor de descargas blindado contra fallos de red.
1.  Entra en un episodio.
2.  Pulsa **Descargar**.
3.  **Monitorización Inteligente:**
    *   Si la descarga se detiene (se va el WiFi, servidor lento), el sistema "Watchdog" lo detecta a los 60 segundos.
    *   Automáticamente cancela el proceso zombie y lo reinicia desde donde se quedó (si el servidor lo permite) o desde cero.
    *   Tú solo relájate: la app se asegura de que el archivo llegue al 100%.

---

## 5. ⚡ Optimización de Rendimiento (PCs Antiguos)

Hemos implementado un "Modo Eco" automático para hardware modesto.
*   **Detección de Núcleos:**
    *   Si tu PC tiene **menos de 4 núcleos**, la app entra en modo "Low-Spec".
    *   Las carátulas se cargan más despacio (paralelismo reducido) para no bloquear la interfaz.
    *   Se reduce el uso de memoria RAM decodificando imágenes a menor resolución (400px).

---

## 6. 🛠️ Solución de Problemas Frecuentes

### 🔵 Linux: Pantalla Azul en el Vídeo
*   **Síntoma:** El audio se oye pero el vídeo es un cuadro azul sólido.
*   **Razón:** Tu gráfica no soporta `OpenGL` moderno o los drivers `mpv` fallan.
*   **Solución:** No hagas nada. Espera 2 segundos. La app detectará el fallo y cambiará sola a renderizado por software (`sw`).

### ❌ Error "Video no disponible" o "Geobloqueo"
*   **Razón:** Tu cookie ha caducado o no tienes permisos para ese contenido.
*   **Solución:** Vuelve a obtener la cookie desde el navegador (paso 3) y actualízala en Ajustes.

### 🐌 La app va lenta al hacer scroll
*   Estamos cargando muchas imágenes de alta resolución.
*   En la versión **v1.0** hemos limitado el tamaño en memoria (`memCacheHeight`), lo que debería haber solucionado esto en el 90% de los casos.

---

## 7. ⚖️ Notas Legales y Responsabilidad

Este software es un proyecto educativo para demostrar capacidades de **Flutter** y **Clean Architecture**.
*   No alojamos contenido.
*   No puenteamos DRM (el contenido se reproduce usando tus credenciales legítimas).
*   El uso de la aplicación es responsabilidad del usuario.

---
*Manual actualizado a la versión v1.0 (Enero 2026)*
