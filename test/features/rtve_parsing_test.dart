import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tvflix/core/entities/content_source.dart';
import 'package:tvflix/features/episodes/data/datasources/rtve_episodes_remote_data_source.dart';
import 'package:tvflix/features/episodes/data/models/episode_model.dart';
import 'package:tvflix/features/programs/data/datasources/rtve_programs_remote_data_source.dart';
import 'package:tvflix/features/programs/data/models/program_model.dart';

// Fixtures: trimmed responses of the RTVE API captured on 2026-11-20.
String fixture(String name) => File('test/fixtures/rtve/$name').readAsStringSync();

void main() {
  group('RTVE programs (api/medios/850/programas.json)', () {
    final programs = RtveProgramsRemoteDataSource.parsePrograms(fixture('programas_page.json'));

    test('parses every item as an RTVE program', () {
      expect(programs, hasLength(2));
      expect(programs.every((p) => p.source == ContentSource.rtve), isTrue);
    });

    test('maps id, title, channel and server-scaled images', () {
      final p = programs.firstWhere((p) => p.id == '1031215');
      expect(p.title, 'Cosas nuestras');
      expect(p.channel, 'La 1');
      expect(p.description, isNotEmpty);
      expect(p.imageUrlVertical, 'https://img.rtve.es/p/1031215?imgProgApi=imgPoster&w=400');
      expect(p.imageUrlHorizontal, 'https://img.rtve.es/p/1031215?imgProgApi=imgPortada&w=400');
    });

    test('falls back to the thumbnail when there is no poster', () {
      final p = ProgramModel.fromRtveJson({
        'id': '42',
        'name': 'Sin póster',
        'imgPoster': '',
        'thumbnail': 'https://img.rtve.es/p/42?imgProgApi=imgPortada&w=400',
      });
      expect(p.imageUrlVertical, 'https://img.rtve.es/p/42?imgProgApi=imgPortada&w=400');
      expect(p.channel, 'RTVE');
    });

    test('an empty page (past the last one) yields no programs', () {
      expect(RtveProgramsRemoteDataSource.parsePrograms('{"page":{"items":[],"number":99}}'), isEmpty);
    });

    test('survives the database round trip with its source', () {
      final p = programs.first;
      expect(ProgramModel.fromDb(p.toJson()), p);
    });

    test('rows cached before sources existed are Atresplayer', () {
      final row = {'id': 'abc', 'title': 't', 'description': 'd', 'channel': 'Antena 3', 'source': null};
      expect(ProgramModel.fromDb(row).source, ContentSource.atresplayer);
    });
  });

  group('RTVE videos (api/programas/{id}/videos.json)', () {
    final episodes = RtveEpisodesRemoteDataSource.parseVideos(fixture('videos_page.json'));

    test('parses full episodes with their DRM flag', () {
      expect(episodes.map((e) => e.id), ['17315137', '17320482']);
      expect(episodes.every((e) => e.source == ContentSource.rtve), isTrue);
      expect(episodes[0].drmProtected, isFalse); // Cosas nuestras
      expect(episodes[1].drmProtected, isTrue); // La Revuelta: hasDRM
    });

    test('maps title, season, description, duration, date and thumbnail', () {
      final plain = episodes[0];
      expect(plain.title, 'Programa 14');
      expect(plain.description, startsWith("Esta tarde en 'Cosas Nuestras'"));
      expect(plain.duration, '73 min'); // 4380570 ms
      expect(plain.publishDate, 1794766500000);
      expect(plain.imageUrl, 'https://img.rtve.es/v/17315137?w=400');

      expect(episodes[1].title, 'Temporada 3 · Alberto San Juan y David Jiménez');
    });

    test('skips withdrawn videos (pubState DESPU)', () {
      const body = '{"page":{"items":['
          '{"id":"1","title":"a","pubState":{"code":"DESPU"}},'
          '{"id":"2","title":"b","pubState":{"code":"ENPUB"}}]}}';
      expect(RtveEpisodesRemoteDataSource.parseVideos(body).map((e) => e.id), ['2']);
    });

    test('survives the database round trip with source and DRM flag', () {
      for (final e in episodes) {
        expect(EpisodeModel.fromDb(e.toJson()), e);
      }
    });
  });
}
