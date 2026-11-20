import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/entities/content_source.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/hls_utils.dart';
import '../../../core/utils/logger_service.dart';

/// A live TV channel offered by Atresplayer or RTVE.
class LiveChannel {
  final String id;
  final String name;
  final ContentSource source;

  const LiveChannel({required this.id, required this.name, this.source = ContentSource.atresplayer});
}

/// A resolved live stream: the playable HLS URL plus the programme on air.
class LiveStream {
  final String url;
  final String? programTitle;

  const LiveStream({required this.url, this.programTitle});
}

/// Resolves live streams from the public Atresplayer player API and from RTVE.
///
/// No account or cookie is needed. The returned URL embeds a token that
/// expires after several hours, so ask for a fresh one on every playback.
class LiveService {
  final http.Client client;

  LiveService({required this.client});

  // RTVE only has 24h and Clan without DRM. La 1, La 2, Teledeporte and the
  // regional La 1 feeds are SAMPLE-AES/FairPlay protected, so they are not offered.
  static const channels = [
    LiveChannel(id: '5a6a165a7ed1a834493ebf6a', name: 'Antena 3'),
    LiveChannel(id: '5a6a172c7ed1a834493ebf6b', name: 'laSexta'),
    LiveChannel(id: '1694255', name: '24h', source: ContentSource.rtve),
    LiveChannel(id: '5466990', name: 'Clan', source: ContentSource.rtve),
  ];

  // Preferred first: the "legacy" HLS ladder (audio+video muxed, no separate audio/subtitle
  // renditions). The standard master playlist, with EXT-X-MEDIA groups, is not recognised as HLS
  // by the libmpv build shipped for Android (mpv falls back to "plaintext playlist" and never plays).
  // The remaining entries are DASH/4K/SSAI variants we don't need.
  static const _preferredTypes = ['application/hls+legacy', 'application/vnd.apple.mpegurl'];

  /// Country Atresplayer sees for this device (live TV is geo-restricted to Spain).
  Future<void> _logIpLocation() async {
    try {
      final response = await client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/client/v1/ipLocation'), headers: AppConstants.liveHeaders)
          .timeout(const Duration(seconds: 8));
      print('[LiveService] ipLocation: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('[LiveService] ipLocation failed: $e');
    }
  }

  Future<LiveStream> getStream(LiveChannel channel) {
    switch (channel.source) {
      case ContentSource.atresplayer:
        return _getAtresplayerStream(channel);
      case ContentSource.rtve:
        return _getRtveStream(channel);
    }
  }

  Future<LiveStream> _getAtresplayerStream(LiveChannel channel) async {
    await _logIpLocation();
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/player/v1/live/${channel.id}');
    final response = await client.get(uri, headers: AppConstants.liveHeaders).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ServerException(statusCode: response.statusCode);
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final sources = ((json['sourcesLive'] as List?) ?? const []).whereType<Map>().toList();
    for (final type in _preferredTypes) {
      for (final source in sources) {
        final src = source['src'] as String?;
        if (source['type'] == type && src != null && src.isNotEmpty) {
          print('[LiveService] ${channel.name} ($type): ${Uri.parse(src).host} -> ${json['titulo']}');
          return LiveStream(url: src, programTitle: json['titulo'] as String?);
        }
      }
    }
    throw ServerException(statusCode: response.statusCode);
  }

  /// RTVE's master playlist has EXT-X-MEDIA audio/subtitle groups (see [_preferredTypes]
  /// for why Android can't play that), so the best variant is played directly: its
  /// segments carry both audio and video. Both playlists are checked for encryption.
  Future<LiveStream> _getRtveStream(LiveChannel channel) async {
    // ztnr.rtve.es redirects to the CDN; relative variant URLs resolve against the final URL.
    final (masterUri, master) = await _getPlaylist(Uri.parse('https://ztnr.rtve.es/ztnr/${channel.id}.m3u8'));
    if (HlsUtils.isEncrypted(master)) throw DrmProtectedException();

    final variants = HlsUtils.variants(master, masterUri);
    if (variants.isEmpty) return LiveStream(url: masterUri.toString());

    final (_, media) = await _getPlaylist(variants.first);
    if (HlsUtils.isEncrypted(media)) throw DrmProtectedException();
    LoggerService().debug('[LiveService] ${channel.name}: ${variants.first.host}');
    return LiveStream(url: variants.first.toString());
  }

  Future<(Uri, String)> _getPlaylist(Uri uri) async {
    final response = await client.get(uri, headers: AppConstants.rtveHeaders).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw ServerException(statusCode: response.statusCode);
    final finalUri = response is http.BaseResponseWithUrl ? (response as http.BaseResponseWithUrl).url : uri;
    return (finalUri, response.body);
  }
}
