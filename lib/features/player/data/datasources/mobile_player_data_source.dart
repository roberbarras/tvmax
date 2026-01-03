import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'player_local_data_source.dart';
import '../../../../core/error/exceptions.dart';

/// Mobile-specific implementation of the PlayerDataSource.
///
/// Uses:
/// - [FFmpegKit] for downloading/transcoding HLS streams.
/// - [url_launcher] (not implemented yet) or Intent for playing? 
///   Currently playVideo does nothing or could launch internal player if requested.
class MobilePlayerDataSource implements PlayerLocalDataSource {
  
  @override
  Future<void> playVideo(String url) async {
    // On mobile, we usually define a specific screen or use url_launcher
    // For now, this is a placeholder or could throw "Not Implemented" 
    // if the UI handles navigation to player screen directly.
    // NOTE: The previous code didn't handle mobile playVideo locally at all.
    throw CacheException(); 
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
           Directory? directory = await getExternalStorageDirectory();
           directory ??= await getApplicationDocumentsDirectory();
           path = directory.path;
        }

        final fullPath = '$path/$fileName.mp4';
        
        // Ensure directory exists
        await Directory(path).create(recursive: true);

        // Use FFmpegKit for HLS/m3u8 downloads
           
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
           
        print('[MobileStrategy] Starting FFmpegKit download: $fileName');

        final completer = Completer<void>();

        await FFmpegKit.executeWithArgumentsAsync(cmdArgs, (session) async {
           final returnCode = await session.getReturnCode();
               
           if (ReturnCode.isSuccess(returnCode)) {
              print('[MobileStrategy] FFmpeg success');
              completer.complete();
           } else {
              final logs = await session.getAllLogsAsString();
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

      } catch (e) {
        if (e is Exception && e.toString().contains('Cancelled')) {
           throw e;
        }
        throw Exception('Mobile Download Error: $e');
      }
  }
}
