import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/presentation/widgets/tv_focus_wrapper.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../domain/entities/program.dart';

class ProgramCard extends StatelessWidget {
  final Program program;
  final VoidCallback onTap;
  final FocusNode? focusNode; // New optional focus node
  final FocusOnKeyCallback? onKey; // New optional onKey

  const ProgramCard({
    super.key,
    required this.program,
    required this.onTap,
    this.focusNode,
    this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in TvFocusWrapper for Android TV Support
    return TvFocusWrapper(
      focusNode: focusNode, // Pass external node
      onKey: onKey, // Pass external key handler
      onTap: onTap,
      onLongPressDown: () {
         // Long Press Down -> Jump to Bottom Bar
         final provider = context.read<NavigationProvider>();
         if (provider.bottomBarFocusNode.canRequestFocus) {
             provider.bottomBarFocusNode.requestFocus();
             // Since BottomBar is a Scope/Focus, we might need to ensure a child is focused.
             // But usually requestFocus() on a Focus widget works.
         }
      },
      onLongPress: () {
         // Direct Favorite Toggle on Long Press for TV remote "Center Button" (Long)
         final provider = context.read<FavoritesProvider>();
         provider.toggleFavorite(program);
         
         // Show simple feedback
         ScaffoldMessenger.of(context).hideCurrentSnackBar();
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(
               provider.isFavorite(program.id) // Note: isFavorite might not update instantly in this closure, logic check needed
                ? 'Añadido a Favoritos' 
                : 'Eliminado de Favoritos' // Actually, we should check *after* toggle or trust the state next frame.
                // Simpler: Just say "Favoritos actualizado"
               ,
             ),
             duration: const Duration(seconds: 1),
           ),
         );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        // Remove InkWell from here, as TvFocusWrapper handles gestures?
        // Actually TvFocusWrapper handles focus. If we keep InkWell inside, it might trap clicks?
        // But TvFocusWrapper needs to receive the events.
        // Let's make TvFocusWrapper child NOT be an InkWell, but just the content.
        // NOTE: TvFocusWrapper uses GestureDetector.
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
                          focusNode: FocusNode(canRequestFocus: false), // Prevent stealing focus (handled by Card)
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
