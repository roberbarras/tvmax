import '../../../../core/entities/content_source.dart';
import '../../domain/entities/program.dart';

class ProgramModel extends Program {
  const ProgramModel({
    required super.id,
    required super.title,
    required super.description,
    super.imageUrlHorizontal,
    super.imageUrlVertical,
    required super.channel,
    super.categoryId, // Add this
    super.source,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json, {String? categoryId}) { // Added categoryId param
    final image = json['image'] ?? {};

    return ProgramModel(
      id: json['formatId'] ?? json['contentId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrlHorizontal: image['pathHorizontal']?.endsWith('/') == true ? '${image['pathHorizontal']}default.jpg' : image['pathHorizontal'],
      imageUrlVertical: image['pathVertical']?.endsWith('/') == true ? '${image['pathVertical']}default.jpg' : image['pathVertical'],
      channel: json['mainChannel'] ?? '',
      categoryId: categoryId, // Pass it down
    );
  }

  /// A program from https://www.rtve.es/api/medios/850/programas.json.
  factory ProgramModel.fromRtveJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}';
    final channel = json['channel'];
    final hasPoster = (json['imgPoster'] as String?)?.isNotEmpty ?? false;
    return ProgramModel(
      id: id,
      title: json['name'] ?? json['longTitle'] ?? '',
      description: json['description'] ?? '',
      // The image API scales on the server; the original posters are ~1 MB each.
      imageUrlHorizontal: 'https://img.rtve.es/p/$id?imgProgApi=imgPortada&w=400',
      imageUrlVertical: hasPoster ? 'https://img.rtve.es/p/$id?imgProgApi=imgPoster&w=400' : json['thumbnail'],
      channel: (channel is Map ? channel['title'] as String? : null) ?? 'RTVE',
      source: ContentSource.rtve,
    );
  }

  /// A row of the `programs` cache table (see [toJson]).
  factory ProgramModel.fromDb(Map<String, dynamic> row) {
    return ProgramModel(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      imageUrlHorizontal: row['imageUrlHorizontal'] as String?,
      imageUrlVertical: row['imageUrlVertical'] as String?,
      channel: row['channel'] as String? ?? '',
      source: ContentSource.fromName(row['source'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrlHorizontal': imageUrlHorizontal,
      'imageUrlVertical': imageUrlVertical,
      'channel': channel,
      'source': source.name,
    };
  }
}
