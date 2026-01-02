import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/utils/logger_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;

  SettingsProvider({required this.sharedPreferences});

  static const String _keyDownloadPath = 'download_path';
  static const String _keyCookie = 'auth_cookie';
  static const String _keyDefaultSectionIndex = 'default_section_index';

  String _downloadPath = '';
  String get downloadPath => _downloadPath;

  String _cookie = '';
  String get cookie => _cookie;

  int _defaultSectionIndex = 0;
  int get defaultSectionIndex => _defaultSectionIndex;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _downloadPath = sharedPreferences.getString(_keyDownloadPath) ?? '';
    _cookie = sharedPreferences.getString(_keyCookie) ?? '';
    _defaultSectionIndex = sharedPreferences.getInt(_keyDefaultSectionIndex) ?? 0;

    LoggerService().debug('[Settings] Loaded cookie: ${_cookie.isNotEmpty ? "YES (len=${_cookie.length})" : "NO"}');
    LoggerService().debug('[Settings] Default Section: $_defaultSectionIndex');
    
    if (_downloadPath.isEmpty) {
      // Default to downloads directory
      Directory? directory;
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
         directory = await getDownloadsDirectory();
      } else if (Platform.isAndroid) {
         // On Android, we try to use the external files directory or application documents
         directory = await getExternalStorageDirectory(); // Returns /storage/emulated/0/Android/data/pkg/files
         // Fallback if null
         directory ??= await getApplicationDocumentsDirectory();
      }
      _downloadPath = directory?.path ?? (Platform.isWindows ? 'C:\\Temp' : '/tmp');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setDownloadPath(String path) async {
    _downloadPath = path;
    await sharedPreferences.setString(_keyDownloadPath, path);
    notifyListeners();
  }

  Future<void> setCookie(String value) async {
    // Sanitize: remove newlines and carriage returns
    final sanitized = value.replaceAll('\n', '').replaceAll('\r', '').trim();
    LoggerService().log('[Settings] Saving cookie (len=${sanitized.length}): ${sanitized.substring(0, sanitized.isNotEmpty ? 10 : 0)}...');
    
    _cookie = sanitized;
    await sharedPreferences.setString(_keyCookie, sanitized);
    notifyListeners();
  }

  Future<void> setDefaultSectionIndex(int index) async {
    _defaultSectionIndex = index;
    await sharedPreferences.setInt(_keyDefaultSectionIndex, index);
    notifyListeners();
  }
}
