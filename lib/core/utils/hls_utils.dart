/// Small helpers to inspect HLS playlists and DASH manifests before playing them.
class HlsUtils {
  static final _keyTag = RegExp(r'^#EXT-X-(SESSION-)?KEY:(.*)$', multiLine: true);
  static final _bandwidth = RegExp(r'[:,]BANDWIDTH=(\d+)');

  /// True if the playlist declares encryption (AES-128, SAMPLE-AES, FairPlay...).
  ///
  /// Any key other than METHOD=NONE counts: TVMax only plays clear streams.
  static bool isEncrypted(String playlist) {
    for (final match in _keyTag.allMatches(playlist)) {
      if (!match.group(2)!.contains('METHOD=NONE')) return true;
    }
    return false;
  }

  /// True if a DASH manifest carries a ContentProtection (Widevine, PlayReady...) element.
  static bool isDashProtected(String mpd) => mpd.contains('ContentProtection');

  /// URLs of the variants of a master playlist, highest bandwidth first.
  /// Empty for a media playlist (one that lists segments).
  static List<Uri> variants(String playlist, Uri base) {
    final variants = <(int, Uri)>[];
    final lines = playlist.split('\n').map((l) => l.trim()).toList();
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].startsWith('#EXT-X-STREAM-INF:')) continue;
      final bandwidth = int.tryParse(_bandwidth.firstMatch(lines[i])?.group(1) ?? '') ?? 0;
      for (var j = i + 1; j < lines.length; j++) {
        if (lines[j].isEmpty || lines[j].startsWith('#')) continue;
        variants.add((bandwidth, base.resolve(lines[j])));
        break;
      }
    }
    variants.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final v in variants) v.$2];
  }
}
