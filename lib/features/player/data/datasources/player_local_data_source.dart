import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tvflix/core/utils/ffmpeg_shim.dart';
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


