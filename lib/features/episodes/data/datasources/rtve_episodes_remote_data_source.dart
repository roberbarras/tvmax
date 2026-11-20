import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/hls_utils.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../core/utils/rtve_url_decoder.dart';
import '../models/episode_model.dart';
import 'episodes_remote_data_source.dart';

/// Episodes and stream URLs of RTVE programs (public API, no account).
///
/// DRM is never played or circumvented: videos RTVE flags with `hasDRM`, and
/// streams whose playlist/manifest declares encryption, raise [DrmProtectedException].
class RtveEpisodesRemoteDataSource implements EpisodesRemoteDataSource {
  final http.Client client;

  RtveEpisodesRemoteDataSource({required this.client});

  static const pageSize = 60;

  // The two player profiles RTVE's web player asks for, in the same order.
  static const _managers = ['rtveplayw', 'default'];

  /// Programs with no full episodes (only clips): all their videos are listed instead.
  final Set<String> _withoutFullEpisodes = {};

  @override
  Future<List<EpisodeModel>> getEpisodes(String formatId, {int page = 0}) async {
    final allVideos = _withoutFullEpisodes.contains(formatId);
    var episodes = await _fetchVideos(formatId, page, fullEpisodesOnly: !allVideos);
    if (page == 0 && episodes.isEmpty && !allVideos) {
      _withoutFullEpisodes.add(formatId);
      episodes = await _fetchVideos(formatId, page, fullEpisodesOnly: false);
    }
    return episodes;
  }

  Future<List<EpisodeModel>> _fetchVideos(String programId, int page, {required bool fullEpisodesOnly}) async {
    final type = fullEpisodesOnly ? 'type=${AppConstants.rtveFullEpisodeType}&' : '';
    final uri = Uri.parse(
      '${AppConstants.rtveApiBaseUrl}/programas/$programId/videos.json?${type}page=${page + 1}&size=$pageSize',
    );
    LoggerService().debug('[RtveEpisodesRemoteDataSource] getEpisodes Fetching: $uri');
    final response = await client.get(uri, headers: AppConstants.rtveHeaders);

    // Just past the last page the item list is empty; far past it RTVE answers
    // 400 or its HTML "page not found" instead.
    if (response.statusCode == 400 || response.statusCode == 404) return [];
    if (response.statusCode != 200) throw ServerException(statusCode: response.statusCode);
    return parseVideos(utf8.decode(response.bodyBytes));
  }

  static List<EpisodeModel> parseVideos(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final items = (json['page']?['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .where(isAvailable)
        .map(EpisodeModel.fromRtveJson)
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  /// 'DESPU' (despublicado): the video was withdrawn and can no longer be watched.
  static bool isAvailable(Map<String, dynamic> video) => video['pubState']?['code'] != 'DESPU';

  @override
  Future<String> getStreamingUrl(String contentId) async {
    final video = await _getVideo(contentId);
    if (video == null || !isAvailable(video)) throw ServerException(statusCode: 404);
    if (video['hasDRM'] == true) throw DrmProtectedException();

    final urls = await _decodedUrls(contentId);
    if (urls.isEmpty) throw ServerException(statusCode: 404);
    return pickPlayableUrl(urls);
  }

  Future<Map<String, dynamic>?> _getVideo(String id) async {
    final response = await client.get(
      Uri.parse('${AppConstants.rtveApiBaseUrl}/videos/$id.json'),
      headers: AppConstants.rtveHeaders,
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw ServerException(statusCode: response.statusCode);
    final items = (jsonDecode(utf8.decode(response.bodyBytes))['page']?['items'] as List?) ?? const [];
    return items.whereType<Map<String, dynamic>>().firstOrNull;
  }

  Future<List<String>> _decodedUrls(String id) async {
    for (final manager in _managers) {
      final uri = Uri.parse('https://www.rtve.es/ztnr/movil/thumbnail/$manager/videos/$id.png?q=v2');
      try {
        final response = await client.get(uri, headers: AppConstants.rtveHeaders);
        if (response.statusCode != 200) continue;
        final urls = RtveUrlDecoder.decodeBase64Png(response.body);
        if (urls.isNotEmpty) return urls;
      } catch (e) {
        LoggerService().debug('[RtveEpisodesRemoteDataSource] $manager PNG failed for $id: $e');
      }
    }
    return [];
  }

  /// Chooses the stream to play: HLS first (TVMax's player, quality picker and
  /// downloads all handle it), then DASH, then progressive MP4. Each candidate is
  /// checked for encryption first and a protected one stops the search.
  Future<String> pickPlayableUrl(List<String> urls) async {
    String? withExtension(String ext) {
      for (final url in urls) {
        if (Uri.parse(url).path.endsWith(ext)) return url;
      }
      return null;
    }

    final hls = withExtension('.m3u8');
    if (hls != null) {
      final master = await _getText(hls);
      if (master != null) {
        if (HlsUtils.isEncrypted(master)) throw DrmProtectedException();
        final variants = HlsUtils.variants(master, Uri.parse(hls));
        final media = variants.isEmpty ? null : await _getText(variants.first.toString());
        if (media != null && HlsUtils.isEncrypted(media)) throw DrmProtectedException();
        return hls;
      }
    }

    final dash = withExtension('.mpd');
    if (dash != null) {
      final mpd = await _getText(dash);
      if (mpd != null) {
        if (HlsUtils.isDashProtected(mpd)) throw DrmProtectedException();
        return dash;
      }
    }

    final mp4 = withExtension('.mp4');
    if (mp4 != null) {
      // The host also serves https; Android blocks cleartext traffic.
      final url = mp4.replaceFirst(RegExp(r'^http:'), 'https:');
      if (await _mp4LooksEncrypted(url)) throw DrmProtectedException();
      return url;
    }

    throw ServerException(statusCode: 404);
  }

  Future<String?> _getText(String url) async {
    try {
      final response = await client.get(Uri.parse(url), headers: AppConstants.rtveHeaders);
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      LoggerService().debug('[RtveEpisodesRemoteDataSource] GET $url failed: $e');
      return null;
    }
  }

  /// Best effort: CENC-encrypted MP4s carry `pssh`/`tenc`/`encv`/`enca` boxes in
  /// their header, which RTVE puts at the start of the file.
  Future<bool> _mp4LooksEncrypted(String url) async {
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {...AppConstants.rtveHeaders, 'range': 'bytes=0-262143'},
      );
      if (response.statusCode != 200 && response.statusCode != 206) return false;
      final header = latin1.decode(response.bodyBytes, allowInvalid: true);
      return const ['pssh', 'tenc', 'encv', 'enca'].any(header.contains);
    } catch (_) {
      return false;
    }
  }
}
