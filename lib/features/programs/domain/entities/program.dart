import 'package:equatable/equatable.dart';

class Program extends Equatable {
  final String id; // href or specific ID
  final String title;
  final String description;
  final String? imageUrlHorizontal;
  final String? imageUrlVertical;
  final String channel;
  final String? categoryId;

  const Program({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrlHorizontal,
    this.imageUrlVertical,
    required this.channel,
    this.categoryId,
  });

  @override
  List<Object?> get props => [id, title, description, imageUrlHorizontal, imageUrlVertical, channel, categoryId];
}
