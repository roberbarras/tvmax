import 'package:equatable/equatable.dart';

class Episode extends Equatable {
  final String id; // contentId
  final String title;
  final String description;
  final String? imageUrl;
  final String? duration;
  final int? publishDate;

  const Episode({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.duration,
    this.publishDate,
  });

  @override
  List<Object?> get props => [id, title, description, imageUrl, duration, publishDate];
}
