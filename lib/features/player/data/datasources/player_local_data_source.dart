import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/error/exceptions.dart';

/// Interface for local video playback and storage operations.
abstract class PlayerLocalDataSource {
  /// Launches an external video player (VLC) with the given [url].
  Future<void> playVideo(String url);

  /// Downloads a video stream/file to local storage.
  /// 
  /// [url] is the source URI.
  /// [fileName] is the target filename without extension.
  /// [customPath] optional override for destination directory.
  /// [headers] optional HTTP headers (cookies, user-agent).
  /// [onStart] callback receives the PID/SessionId for cancellation.
  Future<void> downloadVideo(
    String url, 
    String fileName, {
    String? customPath, 
    Map<String, String>? headers, 
    Function(int)? onStart,
  });
}

class PlayerLocalDataSourceImpl implements PlayerLocalDataSource {
  @override
  Future<void> playVideo(String url) async {
    try {
      if (Platform.isLinux || Platform.isWindows) {
         // Run detached to not block the app
         await Process.start('vlc', [url], mode: ProcessStartMode.detached);
      } else if (Platform.isMacOS) {
         await Process.start('open', ['-a', 'vlc', url], mode: ProcessStartMode.detached);
      }
    } catch (e) {
      throw CacheException(); // Generic error for now
    }
  }

  @override
  Future<void> downloadVideo(String url, String fileName, {String? customPath, Map<String, String>? headers, Function(int)? onStart}) async {
      try {
        String path;
        
        if (customPath != null && customPath.isNotEmpty) {
           path = customPath;
        } else {
           Directory? directory;
           if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
              directory = await getDownloadsDirectory();
           } else if (Platform.isAndroid) {
              directory = await getExternalStorageDirectory();
              directory ??= await getApplicationDocumentsDirectory();
           }
           path = directory?.path ?? (Platform.isWindows ? 'C:\\Temp' : '/tmp');
        }

        final fullPath = '$path/$fileName.mp4';
        
        // Ensure directory exists
        await Directory(path).create(recursive: true);

        if (Platform.isAndroid || Platform.isIOS) {
           // Use FFmpegKit for HLS/m3u8 downloads on mobile
           
           final List<String> cmdArgs = [];
           
           if (headers != null && headers.isNotEmpty) {
              final headerBuffer = StringBuffer();
              headers.forEach((key, value) {
                 headerBuffer.write('$key: $value\r\n');
              });
              cmdArgs.add('-headers');
              cmdArgs.add(headerBuffer.toString());
           }
           
           cmdArgs.add('-i');
           cmdArgs.add(url);
           cmdArgs.add('-c');
           cmdArgs.add('copy');
           cmdArgs.add('-bsf:a');
           cmdArgs.add('aac_adtstoasc');
           cmdArgs.add('-y');
           cmdArgs.add(fullPath);
           
           print('[Download] Starting FFmpegKit async: $cmdArgs');

           final completer = Completer<void>();

           await FFmpegKit.executeWithArgumentsAsync(cmdArgs, (session) async {
               final returnCode = await session.getReturnCode();
               
               if (ReturnCode.isSuccess(returnCode)) {
                  print('[Download] FFmpeg success');
                  completer.complete();
               } else {
                  final logs = await session.getAllLogsAsString();
                  final failStackTrace = await session.getFailStackTrace();
                  
                  // Handle cancellation manually
                  if (ReturnCode.isCancel(returnCode)) {
                      completer.completeError(Exception('Cancelled'));
                  } else {
                      completer.completeError(Exception('FFmpeg failed with code $returnCode.\nLogs: $logs'));
                  }
               }
           }).then((session) async {
               final sessionId = await session.getSessionId();
               if (sessionId != null) {
                   onStart?.call(sessionId);
               }
           });

           return completer.future;
           
        } else {
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
            
            print('[Download] Starting yt-dlp process: $args');
            
            final process = await Process.start(executable, args);
            onStart?.call(process.pid);

            final exitCode = await process.exitCode;
            
            if (exitCode != 0) {
               final stderr = await process.stderr.transform(systemEncoding.decoder).join();
               throw Exception('yt-dlp failed: $stderr');
            }
        }
      } catch (e) {
        print('DOWNLOAD ERROR: $e');
        if (e is Exception && e.toString().contains('Cancelled')) {
           throw e;
        }
        if (e is Exception && e.toString().contains('yt-dlp failed')) {
           throw e; 
        }
        throw Exception('Error: $e');
      }
  }
}
