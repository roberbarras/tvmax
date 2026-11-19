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
  // Legacy int keys stored a tab *position* in older tab orders; now the tab name is stored.
  static const String _keyLegacyDefaultSectionIndex = 'default_section_index'; // 0 Programas, 1 Noticias, 2 Series, 3 Documentales, 7 Directo
  static const String _keyLegacyDefaultSectionTab = 'default_section_tab'; // 0 Directo, 1 Programas, 2 Noticias, 3 Series, 4 Documentales
  static const String _keyDefaultSection = 'default_section_name';
  static const String _keyDefaultSubtitleLanguage = 'default_subtitle_language';
  static const String _keyDefaultQuality = 'default_quality';

  String _downloadPath = '';
  String get downloadPath => _downloadPath;

  String _cookie = '';
  String get cookie => _cookie;

  AppTab _defaultSection = AppTab.programs;
  AppTab get defaultSection => _defaultSection;

  String _defaultSubtitleLanguage = 'off'; // 'off', 'es', 'en'
  String get defaultSubtitleLanguage => _defaultSubtitleLanguage;

  String _defaultQuality = 'auto'; // 'auto', '1080', '720', '480'
  String get defaultQuality => _defaultQuality;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AppTab _loadDefaultSection() {
    final name = sharedPreferences.getString(_keyDefaultSection);
    for (final tab in AppTab.values) {
      if (tab.name == name) return tab;
    }
    final byTab = sharedPreferences.getInt(_keyLegacyDefaultSectionTab);
    if (byTab != null) {
      const order = [AppTab.live, AppTab.programs, AppTab.news, AppTab.series, AppTab.documentaries];
      if (byTab >= 0 && byTab < order.length) return order[byTab];
    }
    final legacy = sharedPreferences.getInt(_keyLegacyDefaultSectionIndex);
    if (legacy != null) {
      const order = [AppTab.programs, AppTab.news, AppTab.series, AppTab.documentaries];
      if (legacy == 7) return AppTab.live;
      if (legacy >= 0 && legacy < order.length) return order[legacy];
    }
    return AppTab.programs;
  }

  Future<void> loadSettings() async {
    _downloadPath = sharedPreferences.getString(_keyDownloadPath) ?? '';
    _cookie = sharedPreferences.getString(_keyCookie) ?? '';
    _defaultSection = _loadDefaultSection();
    _defaultSubtitleLanguage = sharedPreferences.getString(_keyDefaultSubtitleLanguage) ?? _defaultSubtitleLanguage;
    _defaultQuality = sharedPreferences.getString(_keyDefaultQuality) ?? _defaultQuality;

    LoggerService().debug('[Settings] Loaded cookie: ${_cookie.isNotEmpty ? "YES (len=${_cookie.length})" : "NO"}');
    LoggerService().debug('[Settings] Default Section: ${_defaultSection.name}');
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

  Future<void> setDefaultSection(AppTab tab) async {
    _defaultSection = tab;
    await sharedPreferences.setString(_keyDefaultSection, tab.name);
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
