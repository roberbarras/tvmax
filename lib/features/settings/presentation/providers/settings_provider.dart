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
  static const String _keyDefaultSubtitleLanguage = 'default_subtitle_language';
  static const String _keyDefaultQuality = 'default_quality';

  String _downloadPath = '';
  String get downloadPath => _downloadPath;

  String _cookie = '';
  String get cookie => _cookie;

  int _defaultSectionIndex = 0;
  int get defaultSectionIndex => _defaultSectionIndex;

  String _defaultSubtitleLanguage = 'off'; // 'off', 'es', 'en'
  String get defaultSubtitleLanguage => _defaultSubtitleLanguage;

  String _defaultQuality = 'auto'; // 'auto', '1080', '720', '480'
  String get defaultQuality => _defaultQuality;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _downloadPath = sharedPreferences.getString(_keyDownloadPath) ?? '';
    _cookie = sharedPreferences.getString(_keyCookie) ?? '';
    
    // TEMPORARY PROVISIONAL COOKIE FOR TESTING
    if (_cookie.isEmpty) {
       _cookie = 'AMCVS_09DCC8AD54D410FF0A4C98A6%40AdobeOrg=1; didomi_token=eyJ1c2VyX2lkIjoiMTliNzU2M2ItNDdkOC02NDhhLThhOGYtMDRlNTBhNDNlNmRkIiwiY3JlYXRlZCI6IjIwMjUtMTItMzFUMTc6MTA6MjcuMTk3WiIsInVwZGF0ZWQiOiIyMDI1LTEyLTMxVDE3OjEwOjI4LjU0NVoiLCJ2ZW5kb3JzIjp7ImVuYWJsZWQiOlsiZ29vZ2xlIiwiYzppbnN0YWdyYW0iLCJjOm9tbml0dXJlLWFkb2JlLWFuYWx5dGljcyIsImM6YWRvYmUtdGFnbWFuYWdlciIsImM6Y2hhcnRiZWF0IiwiYzphbmFsaWdodHMtN215RUgzZWsiLCJjOmF0cmVzbWVkaWEta0hROWlkeHIiXX0sInB1cnBvc2VzIjp7ImVuYWJsZWQiOlsiZ2VvbG9jYXRpb25fZGF0YSIsImRldmljZV9jaGFyYWN0ZXJpc3RpY3MiLCJjb21wYXJ0aXItOWNRTEdMckMiLCJ1c2FyZnVlbnQtTkZWV2IyN3IiXX0sInZlbmRvcnNfbGkiOnsiZW5hYmxlZCI6WyJnb29nbGUiXX0sInZlcnNpb24iOjIsImFjIjoiRFFPQlFBRVlBTElBWFFBMkFCNkFFcUFNUUFtNEJRd0RQZ0htZ1BjQTk0Q0hBRWZBTmdBZXFCQnNDSTRFU1FKYWdUOEFvcUJZY0N4NEZxUU1SQVlwQXptQnJRRGNvSFRnT3JBZGhCR2FDZDRGQkFLZFFXakF1ZEJvR0FBQS5EUU9CUUFFWUFMSUFYUUEyQUI2QUVxQU1RQW00QlF3RFBnSG1nUGNBOTRDSEFFZkFOZ0FlcUJCc0NJNEVTUUphZ1Q4QW9xQlljQ3g0RnFRTVJBWXBBem1CclFEY29IVGdPckFkaEJHYUNkNEZCQUtkUVdqQXVkQm9HQUFBIn0=; euconsent-v2=CQdTAsAQdTAsAAHABBENCLFsAP_gAEPgAAiQKTNR_GbWlr-Tb3aftkeYxP9_hrboQxBgbJk24FzLvW7JwXx2ExNAzKtqIKmRIAu3TBIQNlHBDURVCgKIgFryDMaEyUoTNKJ6BkiFMRI2NYCFxnmwtjWQCY4vp99lUxmB-N7dr82dziy4BHn3a572S1UJCNIYctBfvsZBKT89IEd_x8u4v4-F7pE2-eS1F_pGvp4j9-YlM_dBGxt-TSfb7Pnrl_BSYAEw0KiCMsiAAIFAwggQAKCsIAKBAEAACQNEBACYMCnIGAC6wmQAgBQADBACAAEGAAIAABIAEIgAoAIBACBAIFAAGABAEBAAQMAAYALEQCAAEA0CFMCCAQLABIzKoNMCEABIICWyoQSAIEFcIQiTwCCBERBQAAAgAFAQAAPBYCEkgJGBBAFxBNAAAQAABBAiQIpCzAEFAZotAWBJwGRpAGD5gmSU4AAA.f_wACHwAAAAA; at_check=true; s_fid=43CF711DFA1C6712-14372336E99AE007; s_cc=true; A3PSID=R884-jjHRuniKoVEFkGuNmeEVJ2hph82xCrrDdHiYL-bcH88UWTpaYMbhby1MEjioqKqCoccvWNcSi4-PDXdtg; mbox=PC#5e90e714474c4470b35ec336504199cd.37_0#1830555979|session#4678e4a1cf494bc0bfc0245f0a55dbb5#1767313039; _cs_mk_aa=0.9457953633002049_1767311178589; s_sq=atresmediaproglobal%3D%2526c.%2526a.%2526activitymap.%2526page%253Datresplayer.com%25253Adocumentales%25253A%2526link%253DLos%252520Borbones%25253A%252520una%252520familia%252520real%2526region%253Dsee-all-items%2526pageIDType%253D1%2526.activitymap%2526.a%2526.c%2526pid%253Datresplayer.com%25253Adocumentales%25253A%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Fwww.atresplayer.com%25252Fdocumentales%25252Flos-borbones-una-familia-real%25252F%2526ot%253DA; AMCV_09DCC8AD54D410FF0A4C98A6%40AdobeOrg=179643557%7CMCIDTS%7C20454%7CMCMID%7C09072064066422981036368717750133809649%7CMCAID%7CNONE%7CMCOPTOUT-1767318437s%7CNONE%7CvVersion%7C5.5.0';
       LoggerService().debug('[Settings] 🍪 Using PROVISIONAL TEST COOKIE.');
    }

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
