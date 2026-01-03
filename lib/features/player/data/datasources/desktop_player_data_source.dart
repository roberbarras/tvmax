import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'player_local_data_source.dart';
import '../../../../core/error/exceptions.dart';

/// Desktop-specific implementation of the PlayerDataSource.
///
/// Uses:
/// - [yt-dlp] binary for downloading.
/// - [VLC] binary for playback (if local).
class DesktopPlayerDataSource implements PlayerLocalDataSource {
  
  @override
  Future<void> playVideo(String url) async {
    try {
      if (Platform.isMacOS) {
         await Process.start('open', ['-a', 'vlc', url], mode: ProcessStartMode.detached);
      } else {
         // Linux & Windows
         await Process.start('vlc', [url], mode: ProcessStartMode.detached);
      }
    } catch (e) {
      print('Desktop Play Error: $e');
      throw CacheException();
    }
  }

  @override
  Future<void> downloadVideo(
    String url, 
    String fileName, {
    String? customPath, 
    Map<String, String>? headers, 
    Function(int)? onStart,
  }) async {
      try {
        String path;
        
        if (customPath != null && customPath.isNotEmpty) {
           path = customPath;
        } else {
           final directory = await getDownloadsDirectory();
           path = directory?.path ?? (Platform.isWindows ? 'C:\\Temp' : '/tmp');
        }

        final fullPath = '$path/$fileName.mp4';
        
        // Ensure directory exists
        await Directory(path).create(recursive: true);

        // Desktop: Try yt-dlp
        String executable = 'yt-dlp';
        if (await File('yt-dlp').exists()) {
           executable = './yt-dlp';
        }
            
        List<String> args = ['-o', fullPath, url];
            
        if (headers != null && headers.containsKey('Cookie')) {
           args.add('--add-header');
           args.add('Cookie:${headers['Cookie']}');
               
           if (headers.containsKey('user-agent')) {
              args.add('--user-agent');
              args.add(headers['user-agent']!);
           }
        }
            
        print('[DesktopStrategy] Starting yt-dlp process: $args');
            
        final process = await Process.start(executable, args);
        onStart?.call(process.pid);

        final exitCode = await process.exitCode;
            
        if (exitCode != 0) {
           final stderr = await process.stderr.transform(utf8.decoder).join();
           throw Exception('yt-dlp failed: $stderr');
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('yt-dlp failed')) {
           throw e; 
        }
        throw Exception('Desktop Download Error: $e');
      }
  }
}
