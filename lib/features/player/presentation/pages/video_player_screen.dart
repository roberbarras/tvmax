import 'dart:async';
import 'dart:io'; // Required for Platform checks
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late VideoController controller;
  Timer? _saveProgressTimer;

  // State to track if we are using HW acceleration
  bool _useHardwareAcceleration = true;
  bool _hasFallenBack = false; // To prevent infinite loops
  bool _autoQualitySet = false; // Tracks if we successfully auto-selected a quality
  final FocusNode _videoFocusNode = FocusNode();

// ... class definition ...

  @override
  void initState() {
    super.initState();
    
    PlayerConfiguration config = const PlayerConfiguration(
      logLevel: MPVLogLevel.info,
    );

    player = Player(configuration: config);
    
    // Attempt to limit Bitrate for HLS (Blind Quality Cap)
    if (Platform.isAndroid) {
       try {
         // Limit to ~2.5 Mbps (good for 720p)
         (player.platform as dynamic).setProperty('hls-bitrate', '2500000');
         print('[VideoPlayer] 📉 Set HLS Bitrate limit to 2.5 Mbps');
       } catch (e) {
         print('[VideoPlayer] ⚠️ Could not set HLS bitrate: $e');
       }
    }
    
    // Listen to logs for HW failures
    player.stream.log.listen((event) {
      if (event.level == MPVLogLevel.error || event.level == MPVLogLevel.warn) {
         print('[MPV] ${event.prefix}: ${event.text}');
      }
      if (_useHardwareAcceleration && !_hasFallenBack) {
         if (event.text.contains('hwaccel') && event.text.contains('error') || 
             event.text.contains('GLSL') && event.text.contains('not supported')) {
            print('[VideoPlayer] ⚠️ Detected HW Acceleration failure. Falling back to Software...');
            _fallbackToSoftware();
         }
      }
    });

    player.stream.error.listen((event) {
      print('[VideoPlayer] ERROR: $event');
    });
    
    player.stream.completed.listen((event) {
       print('[VideoPlayer] Playback completed');
    });

    // Listen to tracks to apply defaults
    player.stream.tracks.listen((tracks) {
       _applyDefaultSettings(tracks);
    });

    _initializeController();
    
    // Get headers with cookie
    final settings = context.read<SettingsProvider>();
    print('[VideoPlayer] Loading with cookie: ${settings.cookie.isNotEmpty ? "YES" : "NO"}');
    final headers = AppConstants.getHeaders(settings.cookie);
    
    // Pass headers to Media
    print('[VideoPlayer] Opening media with headers: $headers');
    player.open(Media(widget.url, httpHeaders: headers));
    
    // Ensure Focus is captured so remote keys work
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoFocusNode.requestFocus();
    });

    _checkSavedProgress();
    _startProgressSaver();
    _checkDeviceCapabilities();
  }

   // Detect Low-End Devices (e.g. Android TV Sticks with < 2GB RAM)
  bool _isLowEndDevice = false;
  Future<void> _checkDeviceCapabilities() async {
     try {
       if (Platform.isAndroid || Platform.isLinux) { // Works on Linux too usually
          // Manual RAM Check via /proc/meminfo
          // This avoids the confusing device_info_plus API changes
          final totalRam = await _getTotalRam();
          
          if (totalRam != null) {
              const lowRamThreshold = 2500 * 1024 * 1024; // 2.5 GB
              if (totalRam < lowRamThreshold) {
                  print('[VideoPlayer] ⚠️ Low-End Device Detected (RAM: ${(totalRam / (1024*1024)).round()} MB).');
                  _isLowEndDevice = true;
              }
          }
       }
     } catch (e) {
       print('[VideoPlayer] Error checking device capabilities: $e');
     }
  }

  Future<int?> _getTotalRam() async {
    try {
      final file = File('/proc/meminfo');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (final line in lines) {
          if (line.startsWith('MemTotal:')) {
            // Format: MemTotal:        16303252 kB
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              final kb = int.tryParse(parts[1]);
              if (kb != null) {
                return kb * 1024; // Convert to Bytes
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  void _initializeController() {
     controller = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: !Platform.isLinux, // Fix Blue Screen on Linux (Force Software)
      ),
    );
  }
  
  void _fallbackToSoftware() {
     _hasFallenBack = true;
     _useHardwareAcceleration = false;
     
     // Re-create controller on the fly
     setState(() {
       // Dispose old one implicitly by overwriting? 
       // VideoController doesn't have a dispose method we call manually usually, 
       // but we should check documentation. Usually updating the state with new controller is enough.
       _initializeController();
     });
     
     // Useful: restart playback to clear bad state
     final pos = player.state.position;
     player.open(Media(widget.url, httpHeaders: AppConstants.getHeaders(context.read<SettingsProvider>().cookie)));
     player.seek(pos);
     player.seek(pos);
  }
  
  bool _defaultsApplied = false;

  void _applyDefaultSettings(Tracks tracks) {
    if (_defaultsApplied) return;
    
    // Only apply if we actually have tracks
    if (tracks.video.isEmpty && tracks.subtitle.isEmpty) return;
    
    // LOG ALL TRACKS FOR DEBUGGING
    print('[VideoPlayer] 📋 Available Video Tracks:');
    for (var t in tracks.video) {
       print('  - ID: ${t.id}, Res: ${t.w}x${t.h}, Bitrate: ${t.bitrate}, Codec: ${t.codec}');
    }

    final settings = context.read<SettingsProvider>();
    final defSub = settings.defaultSubtitleLanguage; // 'off', 'es', 'en'
    final defQual = settings.defaultQuality; // 'auto', '1080', '720'

    print('[VideoPlayer] Applying Defaults -> Subtitle: $defSub, Quality: $defQual');

    // 1. Apply Subtitle Default
    player.setSubtitleTrack(SubtitleTrack.no());
    
    if (defSub != 'off' && defSub != 'auto') {
       try {
         final match = tracks.subtitle.firstWhere(
           (t) {
             final lang = (t.language ?? t.title ?? '').toLowerCase();
             return lang.contains(defSub.toLowerCase());
           },
           orElse: () => SubtitleTrack.no(), 
         );
         if (match != SubtitleTrack.no()) {
             player.setSubtitleTrack(match);
         }
       } catch (e) {
         print('[VideoPlayer] Error matching subtitle: $e');
       }
    }

    // 2. Apply Quality Default
    if (_isLowEndDevice && defQual == 'auto') {
         // Check if we have tracks. If not, wait for them.
        if (player.state.tracks.video.isEmpty) {
           print('[VideoPlayer] ⏳ No tracks yet. Waiting for track list to populate...');
           StreamSubscription? sub;
           sub = player.stream.tracks.listen((tracks) {
              if (tracks.video.isNotEmpty) {
                 print('[VideoPlayer] 📦 Tracks received: ${tracks.video.length}');
                 _applySmartQuality(tracks.video);
                 sub?.cancel();
              }
           });
        } else {
           _applySmartQuality(player.state.tracks.video);
        }
    } 

    if (!_autoQualitySet && defQual != 'auto') {
      try {
         // Parse target height
         final targetH = int.tryParse(defQual) ?? 1080;
         
         // Find closest match
         final sorted = List.of(tracks.video);
         sorted.sort((a, b) {
            final hA = a.h ?? 0;
            final hB = b.h ?? 0;
            return (hA - targetH).abs().compareTo((hB - targetH).abs());
         });
         
         if (sorted.isNotEmpty) {
           final best = sorted.first;
           print('[VideoPlayer] Auto-selecting quality: ${best.w}x${best.h}');
           player.setVideoTrack(best);
         }
      } catch (e) {
         print('[VideoPlayer] Error setting quality: $e');
      }
    }

    _defaultsApplied = true;
  }
  
  // ... rest of methods ... 
  
  // WAIT, I need to match the indentation and context of the original file exactly.
  // The original has `timer` and `initState`. I am replacing a huge chunk.
  
  // Let's stick to the plan: Modify initState and add the helper methods.
  // I will make `controller` NOT `final` so I can reassign it.
  // Original: `late final VideoController controller;` -> `late VideoController controller;`
  
  // I need to use `multi_replace` to change the declaration AND the init logic.

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
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Calidad', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          children: player.state.tracks.video.map((track) {
             final isSelected = player.state.track.video == track;
             
             String label = 'Auto';
             if (track.w != null && track.w! > 0) {
                label = '${track.w}x${track.h}';
                if (track.bitrate != null) {
                  label += ' (${(track.bitrate! / 1000).round()} kbps)';
                }
             }

             return SimpleDialogOption(
               onPressed: () {
                  player.setVideoTrack(track);
                  Navigator.pop(context);
               },
               child: Container(
                 padding: const EdgeInsets.symmetric(vertical: 8),
                 decoration: isSelected 
                   ? BoxDecoration(border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(4)) 
                   : null,
                 child: Row(
                   children: [
                     if (isSelected) const Icon(Icons.check, color: Colors.orange, size: 16),
                     if (isSelected) const SizedBox(width: 8),
                     Text(label, style: TextStyle(color: isSelected ? Colors.orange : Colors.white)),
                   ],
                 ),
               ),
             );
          }).toList(),
        );
      },
    );
  }

  void _showSubtitleSelection() {
    showDialog(
      context: context,
      builder: (context) {
         final subtitles = [SubtitleTrack.no(), ...player.state.tracks.subtitle];
         
         return SimpleDialog(
          title: const Text('Subtítulos', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          children: subtitles.map((track) {
             final isSelected = player.state.track.subtitle == track;
             
              String label;
              if (track == SubtitleTrack.no()) {
                label = 'Desactivar';
              } else {
                final lang = track.language?.toLowerCase();
                if (lang == 'es' || lang == 'spa') label = 'Español';
                else if (lang == 'en' || lang == 'eng') label = 'Inglés';
                else label = track.title ?? track.language ?? 'Pista ${subtitles.indexOf(track)}';
              }

             return SimpleDialogOption(
               onPressed: () {
                  player.setSubtitleTrack(track);
                  Navigator.pop(context);
               },
               child: Container(
                 padding: const EdgeInsets.symmetric(vertical: 8),
                 decoration: isSelected 
                   ? BoxDecoration(border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(4)) 
                   : null,
                 child: Row(
                   children: [
                     if (isSelected) const Icon(Icons.check, color: Colors.orange, size: 16),
                     if (isSelected) const SizedBox(width: 8),
                     Text(label, style: TextStyle(color: isSelected ? Colors.orange : Colors.white)),
                   ],
                 ),
               ),
             );
          }).toList(),
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
      appBar: null, // Removed AppBar to allow Auto-Hide via Controls
      extendBodyBehindAppBar: true, 
      body: Center(
        child: isMobile 
        ? MaterialVideoControlsTheme(
            normal: MaterialVideoControlsThemeData(
              seekBarPositionColor: Colors.orange,
              seekBarThumbColor: Colors.orange,
              bottomButtonBar: [
                 const MaterialPlayOrPauseButton(),
                 const MaterialPositionIndicator(),
                 const Spacer(),
                 IconButton(
                   icon: const Icon(Icons.high_quality, color: Colors.white),
                   onPressed: _showQualitySelection,
                 ),
                 IconButton(
                   icon: const Icon(Icons.subtitles, color: Colors.white),
                   onPressed: _showSubtitleSelection,
                 ),
                 const MaterialFullscreenButton(),
              ],
              topButtonBar: [
                 const BackButton(color: Colors.white),
                 Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            fullscreen: MaterialVideoControlsThemeData(
              seekBarPositionColor: Colors.orange,
              seekBarThumbColor: Colors.orange,
              topButtonBar: [
                 const BackButton(color: Colors.white),
                 Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
              bottomButtonBar: [
                 const MaterialPlayOrPauseButton(),
                 const MaterialPositionIndicator(),
                 const Spacer(),
                 IconButton(
                   icon: const Icon(Icons.high_quality, color: Colors.white),
                   onPressed: _showQualitySelection,
                 ),
                 IconButton(
                   icon: const Icon(Icons.subtitles, color: Colors.white),
                   onPressed: _showSubtitleSelection,
                 ),
                 const MaterialFullscreenButton(),
              ],
            ),
            child: Video(controller: controller),
          )
        : MaterialDesktopVideoControlsTheme(
          normal: MaterialDesktopVideoControlsThemeData(
             seekBarPositionColor: Colors.orange,
             seekBarThumbColor: Colors.orange,
             topButtonBar: [
                const BackButton(color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             ],
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
             topButtonBar: [
                const BackButton(color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             ],
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
  void _applySmartQuality(List<VideoTrack> videoTracks) {
    if (_autoQualitySet) return;
    
    // Sort logic
    final sorted = List<VideoTrack>.from(videoTracks);
    sorted.sort((a, b) => (a.h ?? 0).compareTo(b.h ?? 0));

    print('[VideoPlayer] ⚠ Low-End Device: Forcing 720p or lower.');
    
    final candidates = sorted.where((t) {
        final h = t.h ?? 0;
        return h > 0 && h <= 720;
    }).toList();

    if (candidates.isNotEmpty) {
        final best = candidates.last;
        print('[VideoPlayer] Smart Quality: Selected ${best.w}x${best.h}');
        player.setVideoTrack(best);
        _autoQualitySet = true;
    } else if (sorted.isNotEmpty) {
        // Fallback to smallest valid
        final validSorted = sorted.where((t) => (t.h ?? 0) > 0).toList();
        if (validSorted.isNotEmpty) {
             final best = validSorted.first;
             print('[VideoPlayer] Smart Quality: Fallback to smallest ${best.w}x${best.h}');
             player.setVideoTrack(best);
             _autoQualitySet = true;
        }
    }
  }
}
