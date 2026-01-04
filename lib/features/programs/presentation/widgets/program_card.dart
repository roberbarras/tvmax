import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../domain/entities/program.dart';

class ProgramCard extends StatelessWidget {
  final Program program;
  final VoidCallback onTap;

  const ProgramCard({
    super.key,
    required this.program,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (program.imageUrlVertical != null)
                    CachedNetworkImage(
                      imageUrl: program.imageUrlVertical!,
                      fit: BoxFit.cover,
                      // Optimize memory: Decode only to 400px height (enough for grid items)
                      memCacheHeight: 400,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  else
                    Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(Icons.movie, size: 50, color: Colors.white54),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        program.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, _) {
                        final isFav = favoritesProvider.isFavorite(program.id);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.white,
                            shadows: const [
                               Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black)
                            ],
                          ),
                          onPressed: () {
                             favoritesProvider.toggleFavorite(program);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
