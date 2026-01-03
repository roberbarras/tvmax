# TVMax (Unofficial Atresplayer Client)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Provider](https://img.shields.io/badge/State-Provider-blueviolet?style=for-the-badge)
![License](https://img.shields.io/badge/License-Copyright-red?style=for-the-badge)


Aplicación multiplataforma (Android, Linux, Windows) para navegar, reproducir y descargar contenido de Atresplayer. Diseñada para ser rápida, privada y funcional, eliminando la publicidad intrusiva y ofreciendo una experiencia premium sin coste adicional (usando tu propia cuenta o contenido gratuito).

> [!WARNING]
> Esta es una aplicación no oficial con fines educativos. Requiere una cuenta de Atresplayer para contenidos premium (cookie configurada manualmente). Si no tienes licencia adjunta, el código tiene Copyright exclusivo del autor.

## ✨ Características Principales

- 📱 **Multiplataforma**: Funciona en Android, Linux y Windows.
- 📺 **Navegación Completa**: Explora Programas, Series, Documentales y Noticias.
- ⬇️ **Descargas Avanzadas**:
  - Descarga vídeos HLS (m3u8) a MP4 localmente.
  - **Gestor de Descargas**: Cola de descargas, barra de progreso, notificaciones de sistema.
  - **Cancelación y Reintento**: Control total sobre tus descargas.
- ▶️ **Reproducción Nativa**:
  - **Android**: Reproductor integrado de alto rendimiento (basado en `media_kit`).
  - **Escritorio**: Integración con VLC para máxima compatibilidad.
- ❤️ **Favoritos**: Guarda tus series preferidas localmente.
- 🍪 **Gestión de Sesión**: Configura tu cookie de sesión desde los Ajustes para desbloquear contenido Premium.
- 🎨 **Interfaz Moderna**: Tema oscuro, diseño limpio, iconos personalizados y banners de disponibilidad.

## 🛠️ Requisitos del Sistema

### Android
- Android 7.0 (Nougat) o superior.
- Arquitectura ARM64 (recomendada) o ARMv7.

### Escritorio (Linux/Windows)
- **VLC Media Player**: Debe estar instalado para la reproducción.
  - Linux: `sudo apt install vlc`
  - Windows: [Descargar VLC](https://www.videolan.org/)
- **yt-dlp**: Necesario para las descargas en escritorio.
  - Linux: `sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && sudo chmod a+rx /usr/local/bin/yt-dlp`
  - Windows: Descargar `.exe` y añadir al PATH.

## 🚀 Instalación y Ejecución

### Desde Código Fuente
1. **Prerrequisitos**: Tener Flutter SDK (3.5+) instalado.
2. **Clonar**:
   ```bash
   git clone <repo-url>
   cd TVMax
   ```
3. **Dependencias**:
   ```bash
   flutter pub get
   ```
4. **Ejecutar**:
   - **Android**: Conecta tu móvil con Depuración USB.
     ```bash
     flutter run
     ```
   - **Escritorio**:
     ```bash
     flutter run -d linux  # o windows
     ```

## 🏗️ Arquitectura Técnica

El proyecto sigue una **Clean Architecture** rigurosa para garantizar mantenibilidad y escalabilidad.

### Estructura
```
lib/
├── core/                   # Utiles, Constantes, Errores
├── features/               # Módulos (Episodes, Player, Programs, etc.)
│   ├── data/               # Repositorios, DataSources (API, Local)
│   ├── domain/             # Entidades, Casos de Uso (Lógica de Negocio)
│   └── presentation/       # UI (Screens, Widgets) y Estado (Providers)
└── main.dart               # Entry Point
```

### Tecnologías Clave
- **Flutter**: Framework UI.
- **Provider**: Gestión de estado simple y efectiva.
- **FFmpegKit**: Motor de procesamiento de vídeo en Android (para unir segmentos HLS).
- **MediaKit**: Reproducción de vídeo moderna.
- **Flutter Local Notifications**: Notificaciones nativas de progreso.
- **Sqflite FFI**: Base de datos local para persistencia (Favoritos).
- **Clean Architecture**: Separación de responsabilidades.

## 🔒 Privacidad y Seguridad

- **No Tracking**: La app no recopila datos de uso.
- **Cookies**: Tu cookie de sesión se guarda en tu dispositivo de forma segura (Shared Preferences) y solo se envía a la API oficial de Atresplayer. No se comparte con terceros.
- **Código Abierto**: Puedes auditar el código para verificar que no hay "puertas traseras".

---
*Hecho con ❤️ y Flutter.*
