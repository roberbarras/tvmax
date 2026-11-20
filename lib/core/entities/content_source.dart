/// Where a program, episode or live channel comes from.
///
/// The enum name is what gets stored in the database, so don't rename values.
enum ContentSource {
  atresplayer('Atresplayer'),
  rtve('RTVE');

  final String label;

  const ContentSource(this.label);

  /// Rows saved before sources existed have no value: they are Atresplayer.
  static ContentSource fromName(String? name) {
    for (final source in values) {
      if (source.name == name) return source;
    }
    return ContentSource.atresplayer;
  }
}
