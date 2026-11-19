import 'dart:async';
import 'dart:io'; // Required for Platform checks
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  // Live channel: no resume dialog, no progress saving, no seeking.
  final bool isLive;

  const VideoPlayerScreen({
    super.key, 
    required this.url, 
    required this.title,
    required this.episodeId,
    this.isLive = false,
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

  // --- Android TV (D-pad) controls ---
  static const _overlayHideDelay = Duration(seconds: 4);
  static const _endCountdownSeconds = 5;

  bool? _isTv; // null while detecting (Android only)
  bool _overlayVisible = false;
  Timer? _overlayTimer;
  Duration? _pendingSeek; // Target shown while the user taps left/right
  Timer? _seekDebounce;
  int _seekRepeats = 0;

  // --- End of playback ---
  StreamSubscription<bool>? _completedSub;
  bool _isEnding = false;
  int _endCountdown = _endCountdownSeconds;
  Timer? _endTimer;

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
    
    _completedSub = player.stream.completed.listen((completed) {
       if (completed) {
         print('[VideoPlayer] Playback completed');
         _onPlaybackCompleted();
       }
    });

    // Listen to tracks to apply defaults
    player.stream.tracks.listen((tracks) {
       _applyDefaultSettings(tracks);
    });

    _initializeController();
    
    final headers = _mediaHeaders();
    
    // Pass headers to Media
    print('[VideoPlayer] Opening media (${headers.length} headers)');
    player.open(Media(widget.url, httpHeaders: headers));
    
    _detectTv();
    if (!widget.isLive) {
      _checkSavedProgress();
      _startProgressSaver();
    }
    _checkDeviceCapabilities();
  }

  // Live streams are public, so the session cookie is only sent for on-demand content.
  Map<String, String> _mediaHeaders() {
    if (widget.isLive) return AppConstants.liveHeaders;
    return AppConstants.getHeaders(context.read<SettingsProvider>().cookie);
  }

  // Android TV exposes the leanback feature. There we replace the touch
  // controls with D-pad ones (OK = play/pause, left/right = seek).
  Future<void> _detectTv() async {
    var tv = false;
    if (Platform.isAndroid) {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        tv = info.systemFeatures.contains('android.software.leanback');
      } catch (e) {
        print('[VideoPlayer] Error detecting TV: $e');
      }
    }
    if (!mounted) return;
    setState(() => _isTv = tv);
    if (tv) _showOverlay();
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
     player.open(Media(widget.url, httpHeaders: _mediaHeaders()));
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
  
  @override
  void dispose() {
    _saveProgressTimer?.cancel();
    _overlayTimer?.cancel();
    _seekDebounce?.cancel();
    _endTimer?.cancel();
    _completedSub?.cancel();
    _saveCurrentProgress(); // Save on exit
    _videoFocusNode.dispose();
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
    if (widget.isLive) return;
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
    showDialog<void>(
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
            autofocus: true,
            child: const Text('Continuar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    ).then((_) => _restoreVideoFocus());
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
  
  void _showQualitySelection() {
    final tracks = player.state.tracks.video;
    _showSelectionDialog<VideoTrack>(
      title: 'Calidad',
      items: tracks,
      selected: player.state.track.video,
      labelOf: (track, _) {
        var label = 'Auto';
        if (track.w != null && track.w! > 0) {
          label = '${track.w}x${track.h}';
          if (track.bitrate != null) {
            label += ' (${(track.bitrate! / 1000).round()} kbps)';
          }
        }
        return label;
      },
      onSelect: player.setVideoTrack,
    );
  }

  void _showSubtitleSelection() {
    final subtitles = [SubtitleTrack.no(), ...player.state.tracks.subtitle];
    _showSelectionDialog<SubtitleTrack>(
      title: 'Subtítulos',
      items: subtitles,
      selected: player.state.track.subtitle,
      labelOf: (track, index) {
        if (track == SubtitleTrack.no()) return 'Desactivar';
        final lang = track.language?.toLowerCase();
        if (lang == 'es' || lang == 'spa') return 'Español';
        if (lang == 'en' || lang == 'eng') return 'Inglés';
        return track.title ?? track.language ?? 'Pista $index';
      },
      onSelect: player.setSubtitleTrack,
    );
  }

  // Shared list dialog. The current option gets autofocus so that on a TV the
  // first OK press selects it instead of just moving focus into the dialog.
  Future<void> _showSelectionDialog<T>({
    required String title,
    required List<T> items,
    required T selected,
    required String Function(T item, int index) labelOf,
    required void Function(T item) onSelect,
  }) {
    final selectedIndex = items.indexOf(selected);
    final focusIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 360,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, index) {
              final isSelected = index == selectedIndex;
              return ListTile(
                autofocus: index == focusIndex,
                selected: isSelected,
                selectedColor: Colors.orange,
                textColor: Colors.white,
                leading: isSelected ? const Icon(Icons.check, color: Colors.orange, size: 16) : null,
                title: Text(labelOf(items[index], index)),
                onTap: () {
                  onSelect(items[index]);
                  Navigator.pop(dialogContext);
                },
              );
            },
          ),
        ),
      ),
    ).then((_) => _restoreVideoFocus());
  }

  void _restoreVideoFocus() {
    if (mounted && _isTv == true) _videoFocusNode.requestFocus();
  }

  // ---------------------------------------------------------------------------
  // Android TV remote controls
  // ---------------------------------------------------------------------------

  bool _isSelectKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  bool _isSeekKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.mediaRewind ||
      key == LogicalKeyboardKey.mediaFastForward;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyUpEvent) {
      if (_isSeekKey(key)) _seekRepeats = 0;
      return KeyEventResult.ignored;
    }

    // Playback finished: OK returns right away, Back also works (system pop).
    if (_isEnding) {
      if (event is KeyDownEvent && (_isSelectKey(key) || key == LogicalKeyboardKey.space)) {
        _exitPlayer();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Holding left/right repeats (and accelerates); everything else is once per press.
    if (_isSeekKey(key)) {
      if (widget.isLive) return KeyEventResult.handled; // Nothing to seek in a live stream
      final forward = key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.mediaFastForward;
      _seekBy(forward);
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) {
      // Swallow repeats of keys we own so they don't trigger focus traversal.
      return _isSelectKey(key) || key == LogicalKeyboardKey.space ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    if (_isSelectKey(key) ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.mediaPlayPause) {
      player.playOrPause();
      _showOverlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPlay) {
      player.play();
      _showOverlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPause) {
      player.pause();
      _showOverlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      // First press reveals the bar; once visible, Up = subtitles, Down = quality.
      if (!_overlayVisible) {
        _showOverlay();
      } else if (key == LogicalKeyboardKey.arrowUp) {
        _showSubtitleSelection();
      } else {
        _showQualitySelection();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.contextMenu) {
      _showSubtitleSelection();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showOverlay() {
    if (!_overlayVisible && mounted) setState(() => _overlayVisible = true);
    _scheduleOverlayHide();
  }

  void _scheduleOverlayHide() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(_overlayHideDelay, () {
      if (!mounted || _isEnding) return;
      // Stay visible while loading/paused or while a seek is pending; check again later.
      if (!player.state.playing || _pendingSeek != null) {
        _scheduleOverlayHide();
        return;
      }
      setState(() => _overlayVisible = false);
    });
  }

  // 10 s per tap; holding the key accelerates. The real seek is debounced so
  // we don't flood the HLS stream with requests while the key is held down.
  void _seekBy(bool forward) {
    _seekRepeats++;
    final step = _seekRepeats < 8
        ? 10
        : _seekRepeats < 20
            ? 30
            : 60;
    final duration = player.state.duration;
    final base = _pendingSeek ?? player.state.position;
    var target = base + Duration(seconds: forward ? step : -step);
    if (target < Duration.zero) target = Duration.zero;
    // Stay just short of the end so seeking doesn't trigger "completed" by accident.
    final max = duration - const Duration(seconds: 1);
    if (duration > Duration.zero && target > max) target = max < Duration.zero ? Duration.zero : max;

    setState(() => _pendingSeek = target);
    _showOverlay();

    _seekDebounce?.cancel();
    _seekDebounce = Timer(const Duration(milliseconds: 400), () async {
      final t = _pendingSeek;
      if (t == null) return;
      await player.seek(t);
      if (!mounted) return;
      setState(() => _pendingSeek = null);
      _showOverlay();
    });
  }

  Widget _buildTvOverlay() {
    String fmt(Duration d) => _formatDuration(d < Duration.zero ? Duration.zero : d);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Spinner while buffering (always visible so a stalled stream is obvious)
            Center(
              child: StreamBuilder<bool>(
                stream: player.stream.buffering,
                initialData: player.state.buffering,
                builder: (_, snap) => (snap.data ?? false)
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : const SizedBox.shrink(),
              ),
            ),
            AnimatedOpacity(
              opacity: _overlayVisible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent, Colors.transparent, Colors.black87],
                    stops: [0, 0.25, 0.65, 1],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(48, 32, 48, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Center(
                        child: StreamBuilder<bool>(
                          stream: player.stream.playing,
                          initialData: player.state.playing,
                          builder: (_, snap) => (snap.data ?? false)
                              ? const SizedBox.shrink()
                              : const Icon(Icons.pause_circle_filled, size: 96, color: Colors.white70),
                        ),
                      ),
                    ),
                    if (widget.isLive)
                      Row(
                        children: const [
                          Icon(Icons.circle, size: 12, color: Colors.red),
                          SizedBox(width: 8),
                          Text('EN DIRECTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                    else
                    StreamBuilder<Duration>(
                      stream: player.stream.duration,
                      initialData: player.state.duration,
                      builder: (_, durSnap) {
                        final duration = durSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: player.stream.position,
                          initialData: player.state.position,
                          builder: (_, posSnap) {
                            final position = _pendingSeek ?? posSnap.data ?? Duration.zero;
                            final progress = duration.inMilliseconds > 0
                                ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                                : 0.0;
                            return Row(
                              children: [
                                StreamBuilder<bool>(
                                  stream: player.stream.playing,
                                  initialData: player.state.playing,
                                  builder: (_, snap) => Icon(
                                    (snap.data ?? false) ? Icons.play_arrow : Icons.pause,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(fmt(position), style: const TextStyle(color: Colors.white)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress.toDouble(),
                                    minHeight: 6,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation(Colors.orange),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(fmt(duration), style: const TextStyle(color: Colors.white)),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isLive
                          ? 'OK: pausa / reanudar    ▲: subtítulos    ▼: calidad'
                          : 'OK: pausa / reanudar    ◀ ▶: -10 s / +10 s (mantén para ir más rápido)    ▲: subtítulos    ▼: calidad',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // End of playback: no frozen last frame, 5 s countdown, back to the list
  // ---------------------------------------------------------------------------

  void _onPlaybackCompleted() {
    if (_isEnding || !mounted) return;
    // Ignore spurious "completed" before the stream has loaded.
    if (player.state.duration <= Duration.zero) return;

    _saveProgressTimer?.cancel();
    _seekDebounce?.cancel();
    _overlayTimer?.cancel();
    SharedPreferences.getInstance().then((p) => p.remove('progress_${widget.episodeId}'));

    setState(() {
      _isEnding = true;
      _pendingSeek = null;
      _overlayVisible = false;
      _endCountdown = _endCountdownSeconds;
    });

    _endTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_endCountdown <= 1) {
        timer.cancel();
        _exitPlayer();
      } else {
        setState(() => _endCountdown--);
      }
    });
  }

  void _exitPlayer() {
    _endTimer?.cancel();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    // Close any open dialog (quality, subtitles...) first, then leave the player.
    if (route != null) navigator.popUntil((r) => r == route);
    navigator.pop();
  }

  Widget _buildEndOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _exitPlayer,
        child: Container(
          color: Colors.black, // Covers the frozen last frame
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 72, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Volviendo al listado en $_endCountdown s…',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 24),
              const Text('Pulsa OK para volver ahora', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Still detecting whether this is an Android TV
    if (Platform.isAndroid && _isTv == null) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final isTv = _isTv ?? false;
    // Determine controls based on platform (TV gets its own D-pad controls)
    final isMobile = (Platform.isAndroid || Platform.isIOS) && !isTv;
    
    final video = Center(
        child: isTv
        ? Video(controller: controller, controls: NoVideoControls)
        : isMobile 
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
      );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: null, // Removed AppBar to allow Auto-Hide via Controls
      extendBodyBehindAppBar: true, 
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isTv)
            Focus(
              focusNode: _videoFocusNode,
              autofocus: true,
              onKeyEvent: _onKeyEvent,
              child: video,
            )
          else
            video,
          if (isTv) _buildTvOverlay(),
          if (_isEnding) _buildEndOverlay(),
        ],
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
