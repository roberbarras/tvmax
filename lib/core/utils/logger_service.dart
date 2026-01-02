import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  File? _logFile;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      // On Linux this usually maps to /home/user/Documents or similar, 
      // but for an app it might be better in a hidden folder or the standard app data config.
      // path_provider on Linux usually respects XDG_DATA_HOME.
      
      final logDir = Directory('${directory.path}/TVMax/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File('${logDir.path}/app_log.txt');
      
      // Clear old log on startup or append? Let's append but maybe limit size logic later.
      // For now, just append session start separator.
      await _logFile?.writeAsString('\n\n--- SESSION STARTED: ${DateTime.now()} ---\n', mode: FileMode.append);
      
      print('Logger initialized. File: ${_logFile?.path}');
      _initialized = true;
    } catch (e) {
      print('Failed to initialize logger: $e');
    }
  }

  void log(String message) {
    _write('INFO', message);
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  void debug(String message) {
    _write('DEBUG', message);
    // Only print debug to console in debug mode AND if explicitly desired
    // User wants to "lower log level", so maybe skip DEBUG in console by default
    // if (kDebugMode) print('[DEBUG] $message'); 
  }

  void error(String message, [dynamic error]) {
    final fullMessage = '$message ${error ?? ''}';
    _write('ERROR', fullMessage);
    print('[ERROR] $fullMessage'); // Always print errors to console
  }

  Future<void> _write(String level, String message) async {
    if (_logFile == null) return;
    try {
      final timestamp = DateTime.now().toIso8601String();
      await _logFile?.writeAsString('[$timestamp] [$level] $message\n', mode: FileMode.append);
    } catch (e) {
      // Fail silently to avoid infinite loops if logging fails
    }
  }
}
