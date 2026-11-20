import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tvflix/core/entities/content_source.dart';
import 'package:tvflix/core/error/exceptions.dart';
import 'package:tvflix/core/utils/hls_utils.dart';
import 'package:tvflix/features/episodes/data/datasources/rtve_episodes_remote_data_source.dart';
import 'package:tvflix/features/live/data/live_service.dart';

const _hlsMaster = 'https://rtvehlsvodlote7.rtve.es/mediavodv2/resources/SHO_COSENT/mp4/0/8/1794771083680.mp4/video.m3u8'
    '?hls_no_audio_only=true&hls_client_manifest_version=3&idasset=17315137';

const _master = '''#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=4469000,CODECS="mp4a.40.2,avc1.640029",RESOLUTION=1920x1080
1794771083680-audio=195065-video=4020163.m3u8?idasset=17315137
''';

const _media = '''#EXTM3U
#EXT-X-TARGETDURATION:1
#EXTINF:1, no desc
1794771083680-audio=195065-video=4020163-1.ts?idasset=17315137
''';

const _encryptedMedia = '''#EXTM3U
#EXT-X-KEY:METHOD=SAMPLE-AES,URI="skd://key",KEYFORMAT="com.apple.streamingkeydelivery"
#EXTINF:1,
seg-1.ts
''';

String _video({bool hasDrm = false, String state = 'ENPUB'}) =>
    '{"page":{"items":[{"id":"17315137","hasDRM":$hasDrm,"pubState":{"code":"$state"}}]}}';

void main() {
  final png = File('test/fixtures/rtve/thumbnail_17315137.png.b64').readAsStringSync();

  /// RTVE backend fake. [media] is the variant playlist; [requests] records every URL asked for.
  MockClient rtve({
    String video = '',
    String master = _master,
    String media = _media,
    List<Uri>? requests,
  }) {
    return MockClient((request) async {
      requests?.add(request.url);
      final url = request.url.toString();
      if (request.headers.keys.any((k) => k.toLowerCase() == 'cookie')) {
        fail('A cookie was sent to $url');
      }
      if (url == 'https://www.rtve.es/api/videos/17315137.json') {
        return http.Response(video.isEmpty ? _video() : video, 200);
      }
      if (url.startsWith('https://www.rtve.es/ztnr/movil/thumbnail/rtveplayw/videos/17315137.png')) {
        return http.Response(png, 200);
      }
      if (url == _hlsMaster) return http.Response(master, 200);
      if (url.contains('-video=4020163.m3u8')) return http.Response(media, 200);
      return http.Response('not found', 404);
    });
  }

  group('RtveEpisodesRemoteDataSource.getStreamingUrl', () {
    test('returns the clear HLS master decoded from the PNG', () async {
      final requests = <Uri>[];
      final source = RtveEpisodesRemoteDataSource(client: rtve(requests: requests));
      expect(await source.getStreamingUrl('17315137'), _hlsMaster);
      // Both the master and its variant were inspected for encryption.
      expect(requests.where((u) => u.path.endsWith('.m3u8')), hasLength(2));
    });

    test('videos RTVE flags with hasDRM are refused before any stream request', () async {
      final requests = <Uri>[];
      final source = RtveEpisodesRemoteDataSource(client: rtve(video: _video(hasDrm: true), requests: requests));
      await expectLater(source.getStreamingUrl('17315137'), throwsA(isA<DrmProtectedException>()));
      expect(requests.map((u) => u.host), everyElement('www.rtve.es'));
      expect(requests.any((u) => u.path.contains('thumbnail')), isFalse);
    });

    test('an encrypted variant playlist is refused', () async {
      final source = RtveEpisodesRemoteDataSource(client: rtve(media: _encryptedMedia));
      await expectLater(source.getStreamingUrl('17315137'), throwsA(isA<DrmProtectedException>()));
    });

    test('an encrypted master playlist is refused', () async {
      final source = RtveEpisodesRemoteDataSource(client: rtve(master: _encryptedMedia));
      await expectLater(source.getStreamingUrl('17315137'), throwsA(isA<DrmProtectedException>()));
    });

    test('withdrawn videos are reported as not found', () async {
      final source = RtveEpisodesRemoteDataSource(client: rtve(video: _video(state: 'DESPU')));
      await expectLater(
        source.getStreamingUrl('17315137'),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('a DASH manifest with ContentProtection is refused', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('.mpd')) {
          return http.Response('<MPD><ContentProtection schemeIdUri="urn:uuid:edef8ba9"/></MPD>', 200);
        }
        return http.Response('', 404);
      });
      final source = RtveEpisodesRemoteDataSource(client: client);
      await expectLater(
        source.pickPlayableUrl(['https://example.rtve.es/video.mpd']),
        throwsA(isA<DrmProtectedException>()),
      );
    });

    test('a progressive MP4 is upgraded to https', () async {
      final client = MockClient((request) async => http.Response.bytes(List.filled(64, 0), 206));
      final source = RtveEpisodesRemoteDataSource(client: client);
      expect(
        await source.pickPlayableUrl(['http://rtve-mediavod-lote3.rtve.es/resources/x.mp4?idasset=1']),
        'https://rtve-mediavod-lote3.rtve.es/resources/x.mp4?idasset=1',
      );
    });
  });

  group('RtveEpisodesRemoteDataSource.getEpisodes', () {
    test('far past the last page (400/404) there are no more episodes', () async {
      final source = RtveEpisodesRemoteDataSource(client: MockClient((_) async => http.Response('<html>', 404)));
      expect(await source.getEpisodes('1031215', page: 3), isEmpty);
    });

    test('programs without full episodes list all their videos', () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        final full = request.url.queryParameters['type'] == '39816';
        return http.Response(
          full ? '{"page":{"items":[]}}' : '{"page":{"items":[{"id":"9","title":"Clip"}]}}',
          200,
        );
      });
      final source = RtveEpisodesRemoteDataSource(client: client);
      expect((await source.getEpisodes('77')).map((e) => e.id), ['9']);
      expect(requests.first.queryParameters['type'], '39816');
      expect(requests.last.queryParameters.containsKey('type'), isFalse);

      // Next pages go straight to all videos.
      requests.clear();
      await source.getEpisodes('77', page: 1);
      expect(requests.single.queryParameters['page'], '2');
      expect(requests.single.queryParameters.containsKey('type'), isFalse);
    });
  });

  group('LiveService with RTVE channels', () {
    final channel24h = LiveService.channels.firstWhere((c) => c.name == '24h');
    const liveMaster = '''#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audios",NAME="Castellano",LANGUAGE="spa",DEFAULT=YES,AUTOSELECT=YES
#EXT-X-STREAM-INF:BANDWIDTH=2025472,RESOLUTION=1024x576,AUDIO="audios"
https://rtvelivestream.rtve.es/rtvesec/24h/24h_main_dvr_576.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=3012608,RESOLUTION=1280x720,AUDIO="audios"
https://rtvelivestream.rtve.es/rtvesec/24h/24h_main_dvr_720.m3u8
''';

    test('only 24h and Clan are offered from RTVE', () {
      expect(
        LiveService.channels.where((c) => c.source == ContentSource.rtve).map((c) => c.id),
        ['1694255', '5466990'],
      );
    });

    test('plays the best variant, with a browser user-agent and no cookie', () async {
      final client = MockClient((request) async {
        expect(request.headers.keys.map((k) => k.toLowerCase()), isNot(contains('cookie')));
        expect(request.headers['user-agent'], contains('Mozilla'));
        if (request.url.toString() == 'https://ztnr.rtve.es/ztnr/1694255.m3u8') return http.Response(liveMaster, 200);
        return http.Response(_media, 200);
      });
      final stream = await LiveService(client: client).getStream(channel24h);
      expect(stream.url, 'https://rtvelivestream.rtve.es/rtvesec/24h/24h_main_dvr_720.m3u8');
    });

    test('a SAMPLE-AES live stream is refused', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'ztnr.rtve.es') return http.Response(liveMaster, 200);
        return http.Response(_encryptedMedia, 200);
      });
      await expectLater(LiveService(client: client).getStream(channel24h), throwsA(isA<DrmProtectedException>()));
    });
  });

  group('HlsUtils', () {
    test('METHOD=NONE is not encryption', () {
      expect(HlsUtils.isEncrypted('#EXTM3U\n#EXT-X-KEY:METHOD=NONE\n'), isFalse);
      expect(HlsUtils.isEncrypted(_media), isFalse);
      expect(HlsUtils.isEncrypted('#EXTM3U\n#EXT-X-KEY:METHOD=AES-128,URI="k"\n'), isTrue);
      expect(HlsUtils.isEncrypted('#EXTM3U\n#EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,URI="skd://x"\n'), isTrue);
    });

    test('variants resolve relative URLs and sort by bandwidth', () {
      final variants = HlsUtils.variants(
        '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=100\nlow.m3u8\n#EXT-X-STREAM-INF:BANDWIDTH=900\nhigh.m3u8?x=1\n',
        Uri.parse('https://cdn.example/path/master.m3u8?token=1'),
      );
      expect(variants.map((u) => u.toString()), [
        'https://cdn.example/path/high.m3u8?x=1',
        'https://cdn.example/path/low.m3u8',
      ]);
      expect(HlsUtils.variants(_media, Uri.parse('https://cdn.example/a.m3u8')), isEmpty);
    });
  });
}
