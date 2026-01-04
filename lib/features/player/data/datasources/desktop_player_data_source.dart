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

        // Desktop: Try bundled yt-dlp first, then fallback to global
        String executable = 'yt-dlp';
        
        final exeDir = File(Platform.resolvedExecutable).parent;
        // Check local bundle bin/
        // Linux/Windows usually: <exe_dir>/bin/yt-dlp
        // macOS: <exe_dir>/../../Contents/Resources/bin/yt-dlp (simplified for now)
        
        String bundledPath;
        if (Platform.isWindows) {
           bundledPath = '${exeDir.path}\\bin\\yt-dlp.exe';
        } else {
           bundledPath = '${exeDir.path}/bin/yt-dlp';
        }

        if (await File(bundledPath).exists()) {
           executable = bundledPath;
           print('[DesktopStrategy] Using bundled binary: $executable');
        } else if (Platform.isWindows) {
             // Fallback to CWD or Path
             // Try common debug paths for Windows "flutter run"
             final debugBin = 'windows\\runner\\resources\\bin\\yt-dlp.exe';
             
             if (await File('yt-dlp.exe').exists()) {
                executable = 'yt-dlp.exe'; 
                print('[DesktopStrategy] Found yt-dlp.exe in CWD');
             } else if (await File(debugBin).exists()) {
                executable = debugBin;
                print('[DesktopStrategy] Found yt-dlp.exe in project debug bin');
             } else if (await File('bin/yt-dlp.exe').exists()) {
                executable = 'bin/yt-dlp.exe';
                print('[DesktopStrategy] Found yt-dlp.exe in bin/');
             } else {
                // Try system PATH by just calling 'yt-dlp'
                // But we can't easily check if it exists in PATH without running "where"
                // Let's assume user might have it in PATH
                print('[DesktopStrategy] yt-dlp.exe not found in local paths. Trying system PATH...');
                executable = 'yt-dlp.exe';
             }
        } else {
             if (await File('./yt-dlp').exists()) {
                executable = './yt-dlp';
             }
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

        // Watchdog Logic
        DateTime lastProgressTime = DateTime.now();
        Timer? watchdogTimer;
        bool isStuck = false;

        // Monitor Output for Heartbeat
        process.stdout.transform(utf8.decoder).listen((data) {
           lastProgressTime = DateTime.now();
           // print('[DesktopStrategy] Out: $data'); // Debug only
        });
        process.stderr.transform(utf8.decoder).listen((data) {
           lastProgressTime = DateTime.now();
        });

        watchdogTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
           if (DateTime.now().difference(lastProgressTime).inSeconds > 60) {
              print('[DesktopStrategy] Watchdog triggered! Download stuck for 60s.');
              isStuck = true;
              process.kill(); // This will cause exitCode to be returned (likely non-zero)
              timer.cancel();
           }
        });

        final exitCode = await process.exitCode;
        watchdogTimer.cancel();
            
        if (isStuck) {
           throw DownloadStuckException();
        }

        if (exitCode != 0) {
           // We can't read stderr here because we already listened to it above (streams are single-subscription usually).
           // But we didn't capture it into a buffer.
           // However, if we listen, we drain it.
           // So 'process.stderr...join()' below would hang or be empty?
           // Actually, standard Stream is single-subscription.
           // So line 79 (original) would fail if we attached a listener above.
           // We should just throw generic error or capture logs in the listener.
           throw Exception('yt-dlp failed with exit code $exitCode');
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('yt-dlp failed')) {
           throw e; 
        }
        throw Exception('Desktop Download Error: $e');
      }
  }
}
