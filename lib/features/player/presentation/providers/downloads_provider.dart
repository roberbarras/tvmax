import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/usecases/download_video.dart';
import '../../domain/entities/download_item.dart';
import '../../data/datasources/player_local_data_source.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

import '../../../settings/presentation/providers/settings_provider.dart';

class DownloadsProvider extends ChangeNotifier {
  final PlayerLocalDataSource playerLocalDataSource;
  final SettingsProvider settingsProvider;

  DownloadsProvider({
    required this.playerLocalDataSource, 
    required this.settingsProvider
  }) {
    _initNotifications();
  }

  List<DownloadItem> downloads = [];

  // Stream for errors
  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);
    
    // Request permissions for Android 13+
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> _showNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'downloads_channel',
      'Descargas',
      channelDescription: 'Notificaciones de estado de descargas',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }

  @override
  void dispose() {
    _errorController.close();
    super.dispose();
  }

  void addDownload(String id, String title, String url) {
    if (downloads.any((d) => d.id == id && (d.status == DownloadStatus.downloading || d.status == DownloadStatus.completed))) {
      return; 
    }
    
    // Remove failed item if exists
    downloads.removeWhere((d) => d.id == id);

    final item = DownloadItem(id: id, title: title, url: url, status: DownloadStatus.queued);
    downloads.add(item);
    notifyListeners();
    _startDownload(item);
  }

  void retryDownload(String id) {
    final index = downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      final item = downloads[index];
      if (item.status == DownloadStatus.failed) {
        _startDownload(item);
      }
    }
  }

  Future<void> cancelDownload(String id) async {
    try {
      final item = downloads.firstWhere((d) => d.id == id);
      if (item.status == DownloadStatus.downloading && item.sessionId != null) {
         if (Platform.isAndroid || Platform.isIOS) {
            await FFmpegKit.cancel(item.sessionId!);
         } else {
            Process.killPid(item.sessionId!);
         }
         // The Exception('Cancelled') will be thrown in _startDownload and caught there.
      } else if (item.status == DownloadStatus.queued) {
         downloads.removeWhere((d) => d.id == id);
         notifyListeners();
      }
    } catch (e) {
      print('Error cancelling download: $e');
    }
  }

  Future<void> _startDownload(DownloadItem item) async {
    item.status = DownloadStatus.downloading;
    notifyListeners();

    try {
      // Clean filename
      final fileName = item.title.replaceAll(RegExp(r'[^\w\s\-\.]'), '').trim();
      
      // Get path from settings
      final customPath = settingsProvider.downloadPath;
      
      // We await this now
      await playerLocalDataSource.downloadVideo(
        item.url, 
        fileName, 
        customPath: customPath,
        onStart: (sessionId) {
           item.sessionId = sessionId;
           // notifyListeners(); // Optional, avoiding too many updates
        }
      );
      
      item.status = DownloadStatus.completed;
      item.progress = 1.0;
      item.sessionId = null;
      
      _showNotification(item.id.hashCode, 'Descarga completada', '"${item.title}" se ha descargado correctamente.');
    } catch (e) {
      // Check if cancelled
      if (e.toString().contains('Cancelled')) {
         item.status = DownloadStatus.failed; // Or indicate cancelled
         // Don't show error notification for manual cancellation
         print('Download cancelled by user');
         downloads.removeWhere((d) => d.id == item.id); // Remove from list if cancelled?
      } else {
        item.status = DownloadStatus.failed;
        print('Download failed fully: $e');
        
        String message = 'Error al descargar "${item.title}".';
        if (e is FileSystemException && e.message.contains('No such file')) {
            message = 'Error de almacenamiento. Verifica permisos.';
        }
        
        _errorController.add(message);
        _showNotification(item.id.hashCode, 'Error de descarga', message);
      }
    }
    notifyListeners();
  }
}
