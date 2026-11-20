import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tvflix/core/utils/rtve_url_decoder.dart';

void main() {
  // Captured 2026-11-20 from
  // https://www.rtve.es/ztnr/movil/thumbnail/rtveplayw/videos/17315137.png?q=v2
  // ("Cosas nuestras - Programa 14").
  final fixture = File('test/fixtures/rtve/thumbnail_17315137.png.b64').readAsStringSync();

  test('decodes the HLS, DASH and MP4 URLs hidden in the PNG text chunks', () {
    expect(RtveUrlDecoder.decodeBase64Png(fixture), [
      'https://rtvehlsvodlote7.rtve.es/mediavodv2/resources/SHO_COSENT/mp4/0/8/1794771083680.mp4/video.m3u8'
          '?hls_no_audio_only=true&hls_client_manifest_version=3&idasset=17315137',
      'https://rtvehlsvodlote7.rtve.es/mediavodv2/resources/SHO_COSENT/mp4/0/8/1794771083680.mp4/video.mpd'
          '?idasset=17315137',
      'http://rtve-mediavod-lote3.rtve.es/resources/SHO_COSENT/mp4/0/8/1794771083680.mp4?idasset=17315137',
    ]);
  });

  test('tolerates surrounding whitespace in the response body', () {
    expect(RtveUrlDecoder.decodeBase64Png('\n$fixture\n'), hasLength(3));
  });

  test('returns nothing for a PNG without text chunks', () {
    // 1x1 transparent PNG
    const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
    expect(RtveUrlDecoder.decodeBase64Png(png), isEmpty);
  });
}
