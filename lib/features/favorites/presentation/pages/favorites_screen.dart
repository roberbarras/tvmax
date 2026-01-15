import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../../../programs/presentation/widgets/program_card.dart';
import '../../../episodes/presentation/pages/episodes_screen.dart';
import '../../../episodes/presentation/providers/episodes_provider.dart';
import '../../../../injection_container.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/presentation/widgets/manual_focus_grid.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ManualFocusGridState> _gridGlobalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos ❤️')),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes programas favoritos aún.'),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const maxExtent = 200.0;
              // Padding 16 on each side -> 32 total
              const padding = 32.0;
              const crossAxisSpacing = 16.0;
              
              final availableWidth = width - padding;
              int crossAxisCount = (availableWidth / (maxExtent + crossAxisSpacing)).ceil();
              if (crossAxisCount < 1) crossAxisCount = 1;

              return ManualFocusGrid(
                key: _gridGlobalKey,
                items: provider.favorites,
                crossAxisCount: crossAxisCount,
                itemAspectRatio: 0.7,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: 16.0,
                scrollController: _scrollController,
                // On Favorites, Exit Up just stops at top (standard) or we can focus AppBar if it had actions.
                // It has no actions, so we do nothing (default grid behavior will stop).
                onExitDown: () {
                   final nav = context.read<NavigationProvider>();
                   if (nav.bottomBarFocusNode.canRequestFocus) {
                      nav.bottomBarFocusNode.requestFocus();
                   }
                },
                itemBuilder: (context, index, program, focusNode) {
                   return ProgramCard(
                     program: program,
                     focusNode: focusNode,
                     onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (_) => ChangeNotifierProvider(
                              create: (_) => sl<EpisodesProvider>(),
                              child: EpisodesScreen(program: program),
                           ),
                         ),
                       );
                     },
                   );
                },
              );
            },
          );
        },
      ),
    );
  }
}
