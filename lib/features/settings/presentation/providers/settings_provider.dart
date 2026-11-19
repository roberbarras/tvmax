import 'package:flutter/material.dart';
import '../../../../core/providers/navigation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/utils/logger_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;

  SettingsProvider({required this.sharedPreferences});

  static const String _keyDownloadPath = 'download_path';
  static const String _keyCookie = 'auth_cookie';
  // 'default_section_index' used the old tab order (Programas first). The Directo tab
  // moved to position 0, so positions are stored under a new key.
  static const String _keyLegacyDefaultSectionIndex = 'default_section_index';
  static const String _keyDefaultSectionIndex = 'default_section_tab';
  static const String _keyDefaultSubtitleLanguage = 'default_subtitle_language';
  static const String _keyDefaultQuality = 'default_quality';

  String _downloadPath = '';
  String get downloadPath => _downloadPath;

  String _cookie = '';
  String get cookie => _cookie;

  int _defaultSectionIndex = NavTab.programs;
  int get defaultSectionIndex => _defaultSectionIndex;

  String _defaultSubtitleLanguage = 'off'; // 'off', 'es', 'en'
  String get defaultSubtitleLanguage => _defaultSubtitleLanguage;

  String _defaultQuality = 'auto'; // 'auto', '1080', '720', '480'
  String get defaultQuality => _defaultQuality;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int _loadDefaultSection() {
    final current = sharedPreferences.getInt(_keyDefaultSectionIndex);
    if (current != null) return current;
    final legacy = sharedPreferences.getInt(_keyLegacyDefaultSectionIndex);
    if (legacy == null) return NavTab.programs;
    // Old order: 0 Programas, 1 Noticias, 2 Series, 3 Documentales, 7 Directo
    return legacy == 7 ? NavTab.live : legacy + 1;
  }

  Future<void> loadSettings() async {
    _downloadPath = sharedPreferences.getString(_keyDownloadPath) ?? '';
    _cookie = sharedPreferences.getString(_keyCookie) ?? '';
    _defaultSectionIndex = _loadDefaultSection();
    _defaultSubtitleLanguage = sharedPreferences.getString(_keyDefaultSubtitleLanguage) ?? _defaultSubtitleLanguage;
    _defaultQuality = sharedPreferences.getString(_keyDefaultQuality) ?? _defaultQuality;

    LoggerService().debug('[Settings] Loaded cookie: ${_cookie.isNotEmpty ? "YES (len=${_cookie.length})" : "NO"}');
    LoggerService().debug('[Settings] Default Section: $_defaultSectionIndex');
    LoggerService().debug('[Settings] Default Subtitle: $_defaultSubtitleLanguage');
    LoggerService().debug('[Settings] Default Quality: $_defaultQuality');
    
    if (_downloadPath.isEmpty) {
      // Default to downloads directory
      Directory? directory;
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
         directory = await getDownloadsDirectory();
      } else if (Platform.isAndroid) {
         // Safe default: App Documents (Internal Storage). Guaranteed to work.
         // External storage requires complex permissions on Android 10+.
         directory = await getApplicationDocumentsDirectory(); 
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

  Future<void> setDefaultSubtitleLanguage(String value) async {
    _defaultSubtitleLanguage = value;
    await sharedPreferences.setString(_keyDefaultSubtitleLanguage, value);
    notifyListeners();
  }

  Future<void> setDefaultQuality(String value) async {
    _defaultQuality = value;
    await sharedPreferences.setString(_keyDefaultQuality, value);
    notifyListeners();
  }
}
