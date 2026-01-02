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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrlHorizontal': imageUrlHorizontal,
      'imageUrlVertical': imageUrlVertical,
      'channel': channel,
    };
  }
}
