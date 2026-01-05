# TVMax - Manual de Usuario Avanzado

Este manual detalla todas las funcionalidades, configuración y solución de problemas para **TVMax**.

---

## 1. Introducción

TVMax es un cliente no oficial de código abierto para la plataforma Atresplayer. Su objetivo es ofrecer una experiencia rápida, sin publicidad y privada, permitiendo descargar contenido para verlo offline en cualquier lugar.

---

## 2. Instalación

### Android (Móviles y Tablets)
*   **Requisitos:** Android 7.0 o superior.
*   **Arquitecturas:**
    *   **ARM64 (v8a):** Recomendado para dispositivos modernos (últimos 5-6 años). Mayor rendimiento.
    *   **ARMv7:** Para dispositivos más antiguos o de gama de entrada.
*   **Pasos:**
    1.  Descarga el archivo APK correspondiente.
    2.  Abre el archivo y selecciona "Instalar".
    3.  Si el sistema lo solicita, autoriza la instalación desde "Orígenes Desconocidos" en los ajustes de seguridad.

### Linux (Todas las Distribuciones)
*   Formato **AppImage** (Portable).
*   **Variantes:**
    1.  **Full (Recomendado):** Incluye todas las dependencias (ffmpeg, yt-dlp). Tamaño aproximado: 100MB.
    2.  **Lite:** Tamaño reducido (~18MB). Requiere tener instalados `ffmpeg` y `python3` en el sistema.
*   **Ejecución:**
    1.  Haz clic derecho en el archivo descargado.
    2.  Propiedades > Permisos.
    3.  Marca la casilla "Permitir ejecutar como un programa" (o similar).
    4.  Doble clic para iniciar.

### Windows (10/11)
*   Usa el instalador **setup.exe**.
*   El instalador configura automáticamente las rutas y dependencias necesarias en el sistema. No se requiere configuración manual adicional.

### macOS
*   **Aviso de Seguridad:** Al tratarse de una aplicación no firmada (sin certificado Apple Developer), macOS bloqueará la ejecución inicial.
*   **Pasos para abrir:**
    1.  Descomprime el archivo descargado y mueve la app a la carpeta **Aplicaciones**.
    2.  Intenta abrirla. Si aparece un mensaje de error indicando que no se puede verificar el desarrollador, ciérralo.
    3.  Ve a **Preferencias del Sistema > Seguridad y Privacidad**.
    4.  En la pestaña General, verás un aviso sobre TVMax. Pulsa **Abrir de todas formas**.
    5.  Alternativamente, haz clic derecho sobre la app y selecciona **Abrir**, confirmando la acción en el cuadro de diálogo.

### iOS (iPhone / iPad)
*   **Sideloading:** La instalación requiere métodos alternativos a la App Store.
*   **Método AltStore (Recomendado):**
    1.  Instala AltServer en tu ordenador (Windows/macOS).
    2.  Conecta tu dispositivo iOS por cable.
    3.  Instala AltStore en el dispositivo usando AltServer.
    4.  Descarga el archivo `.ipa` de TVMax (o el ZIP y renómbralo si es necesario) en tu dispositivo.
    5.  Abre AltStore y selecciona el archivo para instalarlo (requiere renovar cada 7 días).

---

## 3. Configuración Vital (Cookies)

Para acceder a capítulos completos, contenido Premium o evitar restricciones geográficas, se recomienda utilizar tu propia cuenta.

1.  **Obtener Cookie:**
    *   Accede a la web oficial de atresplayer.com desde un navegador de escritorio (Chrome/Firefox).
    *   Inicia sesión con tu cuenta.
    *   Abre las Herramientas de Desarrollador (Tecla F12).
    *   Ve a la pestaña **Red (Network)** y recarga la página.
    *   Selecciona la primera petición (normalmente `www.atresplayer.com`).
    *   En la sección "Encabezados de Solicitud" (Request Headers), localiza el campo `Cookie`.
    *   Copia el valor completo de esa línea.

2.  **Configurar en la App:**
    *   Abre TVMax y ve a **Ajustes** (icono de engranaje).
    *   Pega el valor copiado en el campo **Cookie de Sesión**.
    *   Pulsa **Guardar**.
    *   Reinicia la aplicación para aplicar los cambios.

**Nota:** Si tu cuenta es Premium, la aplicación reconocerá el estado y habilitará las funciones exclusivas automáticamente.

---

## 4. Uso de la Aplicación

### Navegación
*   **Barra Inferior:** Acceso rápido a Programas, Series, Documentales, Noticias, Favoritos y Ajustes.
*   **Favoritos:** Utiliza el icono del corazón en la ficha de cualquier contenido para añadirlo a tu lista de seguimiento.

### Reproductor
*   **Calidad de Vídeo:**
    *   Pulsa el botón **HQ** para seleccionar la resolución (1080p, 720p, etc).
    *   En conexiones inestables, se recomienda reducir la calidad manualmente.
*   **Subtítulos:**
    *   Pulsa el botón **CC** para activar o desactivar los subtítulos.
    *   Esta preferencia se puede configurar por defecto en los Ajustes.
*   **Gestos:** Doble toque en los laterales de la pantalla para avanzar o retroceder 10 segundos.

### Gestor de Descargas "Watchdog"
El sistema de descargas está diseñado para ser resiliente a fallos de red.
1.  Selecciona un episodio y pulsa **Descargar**.
2.  El sistema monitorizará el progreso.
3.  Si la conexión se interrumpe, el sistema "Watchdog" detectará el bloqueo y reiniciará la descarga automáticamente, intentando reanudar desde el último punto guardado.

---

## 5. Optimización de Rendimiento

La aplicación incluye un "Modo Eco" automático para equipos con recursos limitados.
*   **Funcionamiento:** Si se detecta un procesador con menos de 4 núcleos o memoria limitada, la aplicación reduce el paralelismo en la carga de imágenes y disminuye la resolución de las miniaturas en memoria para evitar bloqueos y reducir el consumo de RAM.

---

## 6. Solución de Problemas Frecuentes

### Linux: Pantalla Azul / Vídeo no visible
*   **Causa:** Incompatibilidad de los drivers gráficos con la aceleración por hardware de mpv.
*   **Solución:** La aplicación detectará el fallo tras unos segundos y cambiará automáticamente al modo de renderizado por software. No es necesaria intervención del usuario.

### Error "Video no disponible" o Bloqueo Geográfico
*   **Causa:** La cookie de sesión ha caducado o la cuenta no tiene permisos para ese contenido específico.
*   **Solución:** Repite el proceso de obtención de la cookie en el navegador y actualízala en los Ajustes de la aplicación.

### Lentitud al hacer scroll
*   En versiones anteriores esto podía deberse a la carga excesiva de imágenes de alta resolución. La versión actual gestiona la caché de memoria de forma más estricta para mitigar este problema en listas largas.

---

## 7. Notas Legales

Este software es un proyecto educativo diseñado para demostrar conceptos de arquitectura de software.
*   La aplicación no aloja ningún tipo de contenido audiovisual.
*   No se eluden medidas de protección DRM; la reproducción depende legítimamente de las credenciales del usuario.
*   El uso de esta herramienta es responsabilidad exclusiva del usuario final.

---
Manual actualizado: Enero 2026.
