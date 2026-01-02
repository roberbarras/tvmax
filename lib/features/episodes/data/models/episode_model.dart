import '../../domain/entities/episode.dart';

class EpisodeModel extends Episode {
  const EpisodeModel({
    required super.id,
    required super.title,
    required super.description,
    super.imageUrl,
    super.duration,
    super.publishDate,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'duration': duration,
      'publishDate': publishDate,
    };
  }
}
