import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:tvflix/core/utils/ffmpeg_shim.dart';
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
        DateTime lastProgressTime = DateTime.now();
        Timer? watchdogTimer;

        // Watchdog Timer: Checks every 10s if progress is stuck for > 60s
        watchdogTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
           if (DateTime.now().difference(lastProgressTime).inSeconds > 60) {
              print('[MobileStrategy] Watchdog triggered! Download stuck for 60s.');
              // We need the session ID to cancel.
              // FFmpegKit sessions are global, but we handle it via the session object if accessible.
              // Wait, we only get sessionId asynchronously.
              // But we can cancel the completer early.
              // Actually, better to just let the provider retry.
              timer.cancel();
              completer.completeError(DownloadStuckException());
           }
        });

        await FFmpegKit.executeWithArgumentsAsync(
           cmdArgs, 
           (session) async {
               watchdogTimer?.cancel(); // Cancel watchdog on finish
               final returnCode = await session.getReturnCode();
               
               if (ReturnCode.isSuccess(returnCode)) {
                  print('[MobileStrategy] FFmpeg success');
                  if (!completer.isCompleted) completer.complete();
               } else {
                  final logs = await session.getAllLogsAsString();
                  if (ReturnCode.isCancel(returnCode)) {
                      if (!completer.isCompleted) completer.completeError(Exception('Cancelled'));
                  } else {
                      if (!completer.isCompleted) completer.completeError(Exception('FFmpeg failed with code $returnCode.\nLogs: $logs'));
                  }
               }
           }, 
           null, // Log Callback
           (statistics) {
               // Update heartbeat on activity
               lastProgressTime = DateTime.now();
           }
        ).then((session) async {
           final sessionId = await session.getSessionId();
           if (sessionId != null) {
               onStart?.call(sessionId);
               
               // Enhance watchdog cancellation if we have session ID (optional, but cleaner if we cancel FFmpeg too)
               // But completer.completeError(Stuck) relies on the Provider to retry, which re-calls this.
               // The old session will keep running if we don't cancel it? YES.
               // So we MUST cancel the stuck session.
               // We need to capture 'session' here to cancel it in the Timer?
               // The executeWithArgumentsAsync returns a Session object in strict mode, but here it's void/Future.
               // Actually, 'then' returns the session.
               
               // Let's refactor slightly to get session reference for the timer.
           }
        });


        // Wait for result, but handle the watchdog cancellation cleanup
        try {
           await completer.future;
        } catch (e) {
           watchdogTimer?.cancel();
           // If stuck, we should ensure FFmpeg is cancelled.
           // Since we can't easily access the valid session ID *inside* the timer before it returns...
           // Actually, onStart gives us the ID.
           // So the Provider has the ID. Logic: Provider catches StuckException -> Provider calls cancel(id) -> Provider calls retry().
           rethrow;
        }

        return completer.future;

      } catch (e) {
        if (e is Exception && e.toString().contains('Cancelled')) {
           throw e;
        }
        throw Exception('Mobile Download Error: $e');
      }
  }
}
