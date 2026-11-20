import '../../../../core/entities/content_source.dart';
import '../../domain/entities/episode.dart';

class EpisodeModel extends Episode {
  const EpisodeModel({
    required super.id,
    required super.title,
    required super.description,
    super.imageUrl,
    super.duration,
    super.publishDate,
    super.source,
    super.drmProtected,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    final image = json['image'] ?? {};
    final images = image['images'] ?? {};
    final horizontal = images['HORIZONTAL'] ?? {};

    // Sometimes pathHorizontal is directly in image, sometimes in images.HORIZONTAL.path
    var imagePath = horizontal['path'] ?? image['pathHorizontal'];
    if (imagePath != null && imagePath.endsWith('/')) {
      imagePath = '${imagePath}default.jpg';
    }

    return EpisodeModel(
      id: json['contentId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: imagePath,
      duration: json['duration'], // Maybe formatted string
      publishDate: json['publicationDate'],
    );
  }

  /// A row of the `episodes` cache table (see [toJson]).
  factory EpisodeModel.fromDb(Map<String, dynamic> row) {
    return EpisodeModel(
      id: row['contentId'] as String? ?? row['id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      imageUrl: row['imageUrl'] as String?,
      duration: row['duration'] as String?,
      publishDate: row['publishDate'] as int?,
      source: ContentSource.fromName(row['source'] as String?),
      drmProtected: row['drmProtected'] == 1,
    );
  }

  /// A video from https://www.rtve.es/api/programas/{id}/videos.json.
  factory EpisodeModel.fromRtveJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}';
    final title = (json['title'] ?? json['longTitle'] ?? '') as String;
    final season = json['temporada'] as String?;
    final durationMs = json['duration'];
    return EpisodeModel(
      id: id,
      title: season != null && season.isNotEmpty && !title.contains(season) ? '$season · $title' : title,
      description: json['shortDescription'] ?? '',
      // Scaled on the server; the original thumbnails are up to 4000 px wide.
      imageUrl: 'https://img.rtve.es/v/$id?w=400',
      duration: durationMs is int && durationMs > 0 ? '${(durationMs / 60000).round()} min' : null,
      publishDate: json['publicationDateTimestamp'] as int?,
      source: ContentSource.rtve,
      drmProtected: json['hasDRM'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'duration': duration,
      'publishDate': publishDate,
      'source': source.name,
      'drmProtected': drmProtected ? 1 : 0,
    };
  }
}
