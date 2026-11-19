import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/error/exceptions.dart';
import '../../../core/utils/constants.dart';

/// A live TV channel offered by Atresplayer.
class LiveChannel {
  final String id;
  final String name;

  const LiveChannel({required this.id, required this.name});
}

/// A resolved live stream: the playable HLS URL plus the programme on air.
class LiveStream {
  final String url;
  final String? programTitle;

  const LiveStream({required this.url, this.programTitle});
}

/// Resolves live streams from the public Atresplayer player API.
///
/// No account or cookie is needed. The returned URL embeds a token that
/// expires after several hours, so ask for a fresh one on every playback.
class LiveService {
  final http.Client client;

  LiveService({required this.client});

  static const channels = [
    LiveChannel(id: '5a6a165a7ed1a834493ebf6a', name: 'Antena 3'),
    LiveChannel(id: '5a6a172c7ed1a834493ebf6b', name: 'laSexta'),
  ];

  // Plain HLS. The other entries are legacy/DASH/4K/SSAI variants we don't need.
  static const _hlsType = 'application/vnd.apple.mpegurl';

  Future<LiveStream> getStream(LiveChannel channel) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/player/v1/live/${channel.id}');
    final response = await client.get(uri, headers: AppConstants.liveHeaders).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ServerException(statusCode: response.statusCode);
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final sources = (json['sourcesLive'] as List?) ?? const [];
    for (final source in sources) {
      if (source is Map && source['type'] == _hlsType) {
        final src = source['src'] as String?;
        if (src != null && src.isNotEmpty) {
          return LiveStream(url: src, programTitle: json['titulo'] as String?);
        }
      }
    }
    throw ServerException(statusCode: response.statusCode);
  }
}
