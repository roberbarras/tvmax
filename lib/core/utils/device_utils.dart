import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  static bool? _isAndroidTv;

  /// True on Android TV (the leanback feature). Cached after the first call.
  static Future<bool> isAndroidTv() async {
    final cached = _isAndroidTv;
    if (cached != null) return cached;

    var tv = false;
    if (Platform.isAndroid) {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        tv = info.systemFeatures.contains('android.software.leanback');
      } catch (e) {
        print('[DeviceUtils] Error detecting TV: $e');
      }
    }
    return _isAndroidTv = tv;
  }
}
