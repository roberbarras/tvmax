import 'package:equatable/equatable.dart';
import '../../../../core/entities/content_source.dart';

/// Represents a TV Show, Series, or Program in the catalog.
class Program extends Equatable {
  /// Unique identifier defined by the backend (href or contentId).
  final String id; 
  
  /// Display title of the program.
  final String title;
  
  /// Short synopsis or description.
  final String description;
  
  /// URL for the landscape thumbnail (16:9).
  final String? imageUrlHorizontal;
  
  /// URL for the portrait poster (2:3).
  final String? imageUrlVertical;
  
  /// The broadcasting channel (e.g., 'Antena 3', 'La Sexta').
  final String channel;
  
  /// Optional Category ID mainly used for navigation/filtering context.
  final String? categoryId;

  /// Catalog the program belongs to; decides how its episodes are fetched and played.
  final ContentSource source;

  const Program({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrlHorizontal,
    this.imageUrlVertical,
    required this.channel,
    this.categoryId,
    this.source = ContentSource.atresplayer,
  });

  @override
  List<Object?> get props => [id, title, description, imageUrlHorizontal, imageUrlVertical, channel, categoryId, source];
}
