import 'dart:async';
import 'dart:io'; // Required for Platform checks
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/utils/constants.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String episodeId;

  const VideoPlayerScreen({
    super.key, 
    required this.url, 
    required this.title,
    required this.episodeId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;
  Timer? _saveProgressTimer;



// ... class definition ...

  @override
  void initState() {
    super.initState();
    
    // Default configuration with logging
    PlayerConfiguration config = const PlayerConfiguration(
      logLevel: MPVLogLevel.info,
    );

    player = Player(configuration: config);
    
    // Listen to logs
    player.stream.log.listen((event) {
      print('[MPV] ${event.prefix}: ${event.text}');
    });
    
    player.stream.error.listen((event) {
      print('[VideoPlayer] ERROR: $event');
    });
    
    player.stream.completed.listen((event) {
       print('[VideoPlayer] Playback completed');
    });

    // Configure VideoController
    // Enable HW acceleration to avoid crash on high-res videos (S/W crash)
    controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true, 
      ),
    );
    
    // Get headers with cookie
    final settings = context.read<SettingsProvider>();
    print('[VideoPlayer] Loading with cookie: ${settings.cookie.isNotEmpty ? "YES" : "NO"}');
    final headers = AppConstants.getHeaders(settings.cookie);
    
    // Pass headers to Media
    print('[VideoPlayer] Opening media with headers: $headers');
    player.open(Media(widget.url, httpHeaders: headers));
    
    _checkSavedProgress();
    _startProgressSaver();
  }

  @override
  void dispose() {
    _saveProgressTimer?.cancel();
    _saveCurrentProgress(); // Save on exit
    player.dispose();
    super.dispose();
  }

  Future<void> _checkSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPos = prefs.getInt('progress_${widget.episodeId}');
    
    if (savedPos != null && savedPos > 5000) { // More than 5 seconds
       // Pause playback while offering resume option
       await player.pause();
       
       if (mounted) {
         _showResumeDialog(savedPos);
       }
    }
  }

  void _startProgressSaver() {
    _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveCurrentProgress();
    });
  }

  Future<void> _saveCurrentProgress() async {
    final pos = player.state.position.inMilliseconds;
    final duration = player.state.duration.inMilliseconds;
    
    // Save only if valid and not near the end
    if (duration > 0 && pos > 0 && pos < (duration - 5000)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('progress_${widget.episodeId}', pos);
    } else if (duration > 0 && pos >= (duration - 5000)) {
        // Finished or almost finished, remove progress
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('progress_${widget.episodeId}');
    }
  }

  void _showResumeDialog(int positionMs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Reanudar reproducción', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Quieres continuar por donde lo dejaste? (${_formatDuration(Duration(milliseconds: positionMs))})', 
          style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () {
               // Start from beginning
               player.play();
               Navigator.pop(context);
            },
            child: const Text('Empezar de cero'),
          ),
          TextButton(
            onPressed: () async {
               Navigator.pop(context);
               
               print('[RESUME] User chose to resume at $positionMs ms');
               
               // Show a loading indicator (optional, but good UX? For now just logical fix)
               
               // Robust Seek Sequence:
               // 1. Ensure playing to trigger buffering
               await player.play(); 
               
               // 2. Wait until we have a valid duration (metadata loaded)
               // This is the CRITICAL missing step for HLS streams
               bool ready = false;
               int retries = 0;
               while (!ready && retries < 20) { // Max 10 seconds wait
                 if (player.state.duration.inMilliseconds > 0) {
                   ready = true;
                   break;
                 }
                 await Future.delayed(const Duration(milliseconds: 500));
                 retries++;
                 print('[RESUME] Waiting for metadata... ($retries/20)');
               }
               
               if (ready) {
                 print('[RESUME] Metadata loaded. Duration: ${player.state.duration}. Seeking to $positionMs...');
                 await player.seek(Duration(milliseconds: positionMs));
                 print('[RESUME] Seek command sent.');
               } else {
                 print('[RESUME] Timed out waiting for metadata. Seek might fail.');
                 // Try anyway
                 await player.seek(Duration(milliseconds: positionMs));
               }
               
               await player.play(); 
            },
            child: const Text('Continuar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
  
  void _showQualitySelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text('Calidad', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
               const Divider(color: Colors.grey),
               Expanded(
                 child: ListView.builder(
                   itemCount: player.state.tracks.video.length,
                   itemBuilder: (context, index) {
                      final track = player.state.tracks.video[index];
                      final isSelected = player.state.track.video == track;
                      
                      // Format label: e.g. "1920x1080 (3000 kbps)" or "Auto"
                      String label = 'Auto';
                      if (track.w != null && track.w! > 0) {
                         label = '${track.w}x${track.h}';
                         if (track.bitrate != null) {
                           label += ' (${(track.bitrate! / 1000).round()} kbps)';
                         }
                      }
                      
                      return ListTile(
                        leading: isSelected ? const Icon(Icons.check, color: Colors.orange) : const SizedBox(width: 24),
                        title: Text(
                          label, 
                          style: TextStyle(color: isSelected ? Colors.orange : Colors.white),
                        ),
                        onTap: () {
                           player.setVideoTrack(track);
                           Navigator.pop(context);
                        },
                      );
                   },
                 ),
               ),
            ],
          ),
        );
      },
    );
  }

  void _showSubtitleSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
         // Add "Off" option manually
         final subtitles = [SubtitleTrack.no(), ...player.state.tracks.subtitle];
         
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text('Subtítulos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
               const Divider(color: Colors.grey),
               Expanded(
                 child: ListView.builder(
                   itemCount: subtitles.length,
                   itemBuilder: (context, index) {
                      final track = subtitles[index];
                      final isSelected = player.state.track.subtitle == track;
                      
                      String label;
                      if (track == SubtitleTrack.no()) {
                        label = 'Desactivar';
                      } else {
                        // Intelligent formatting for languages
                        final lang = track.language?.toLowerCase();
                        if (lang == 'es' || lang == 'spa') label = 'Español';
                        else if (lang == 'en' || lang == 'eng') label = 'Inglés';
                        else label = track.title ?? track.language ?? 'Pista $index';
                      }
                      
                      return ListTile(
                        leading: isSelected ? const Icon(Icons.check, color: Colors.orange) : const SizedBox(width: 24),
                        title: Text(
                          label, 
                          style: TextStyle(color: isSelected ? Colors.orange : Colors.white),
                        ),
                        onTap: () {
                           player.setSubtitleTrack(track);
                           Navigator.pop(context);
                        },
                      );
                   },
                 ),
               ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine controls based on platform
    final isMobile = Platform.isAndroid || Platform.isIOS;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true, 
      body: Center(
        child: isMobile 
        ? MaterialVideoControlsTheme(
            normal: const MaterialVideoControlsThemeData(
              seekBarPositionColor: Colors.orange,
              seekBarThumbColor: Colors.orange,
              // Add custom buttons here if needed for mobile
            ),
            fullscreen: const MaterialVideoControlsThemeData(
              seekBarPositionColor: Colors.orange,
              seekBarThumbColor: Colors.orange,
            ),
            child: Video(controller: controller),
          )
        : MaterialDesktopVideoControlsTheme(
          normal: MaterialDesktopVideoControlsThemeData(
             seekBarPositionColor: Colors.orange,
             seekBarThumbColor: Colors.orange,
             bottomButtonBar: [
                const MaterialDesktopSkipPreviousButton(),
                const MaterialDesktopPlayOrPauseButton(),
                const MaterialDesktopVolumeButton(),
                const MaterialDesktopPositionIndicator(),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.high_quality, color: Colors.white),
                  tooltip: 'Calidad',
                  onPressed: _showQualitySelection,
                ),
                IconButton(
                  icon: const Icon(Icons.subtitles, color: Colors.white),
                  tooltip: 'Subtítulos',
                  onPressed: _showSubtitleSelection,
                ),
                const MaterialDesktopFullscreenButton(),
             ],
          ),
          fullscreen: MaterialDesktopVideoControlsThemeData(
             seekBarPositionColor: Colors.orange,
             seekBarThumbColor: Colors.orange,
             bottomButtonBar: [
                const MaterialDesktopSkipPreviousButton(),
                const MaterialDesktopPlayOrPauseButton(),
                const MaterialDesktopVolumeButton(),
                const MaterialDesktopPositionIndicator(),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.high_quality, color: Colors.white),
                  tooltip: 'Calidad',
                  onPressed: _showQualitySelection,
                ),
                IconButton(
                  icon: const Icon(Icons.subtitles, color: Colors.white),
                  tooltip: 'Subtítulos',
                  onPressed: _showSubtitleSelection,
                ),
                const MaterialDesktopFullscreenButton(),
             ],
          ),
          child: Video(
            controller: controller,
            controls: MaterialDesktopVideoControls,
          ),
        ),
      ),
    );
  }
}
