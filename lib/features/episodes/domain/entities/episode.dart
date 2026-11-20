import 'package:equatable/equatable.dart';
import '../../../../core/entities/content_source.dart';

class Episode extends Equatable {
  final String id; // contentId
  final String title;
  final String description;
  final String? imageUrl;
  final String? duration;
  final int? publishDate;
  final ContentSource source;
  /// The provider marks this episode as DRM-protected: it is listed but never played.
  final bool drmProtected;

  const Episode({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.duration,
    this.publishDate,
    this.source = ContentSource.atresplayer,
    this.drmProtected = false,
  });

  @override
  List<Object?> get props => [id, title, description, imageUrl, duration, publishDate, source, drmProtected];
}
