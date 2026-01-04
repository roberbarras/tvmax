# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# MediaKit
-keep class com.alexmercerind.mediakitandroidhelper.** { *; }

# FFmpegKit
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Internet Permission check (sometimes stripped if not explicit)
-keep class android.net.** { *; }

# Coroutines (used by plugins)
-keep class kotlinx.coroutines.** { *; }

# Google Play Core (Split Install stuff, ignored since we don't use dynamic features)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.finsky.**

# Aggressive Keep for MediaKit / FFI
-keep class com.alexmercerind.mediakitandroidhelper.** { *; }
-keep class video.api.player.** { *; }
-keep class com.arthenica.** { *; }
-keep class com.antonkarpenko.** { *; } # CRITICAL: Used by ffmpeg_kit_flutter_new
-keepnames class com.arthenica.** { *; }
-keepnames class com.antonkarpenko.** { *; }
-keepattributes *Annotation*

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
