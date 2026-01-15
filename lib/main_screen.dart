import 'package:flutter/material.dart';
import '../../features/programs/presentation/pages/programs_screen.dart';
import '../../features/programs/presentation/pages/news_screen.dart';
import '../../features/programs/presentation/pages/series_screen.dart';
import '../../features/programs/presentation/pages/documentaries_screen.dart';
import '../../features/favorites/presentation/pages/favorites_screen.dart';
import '../../features/player/presentation/pages/downloads_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';

import 'package:provider/provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../features/player/presentation/providers/downloads_provider.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Removed local _selectedIndex

  final List<Widget> _screens = const [
    ProgramsScreen(),
    NewsScreen(),
    SeriesScreen(),
    DocumentariesScreen(),
    FavoritesScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final downloadsProvider = context.read<DownloadsProvider>();
      downloadsProvider.errorStream.listen((message) {
        if (mounted) {
           _showErrorNotification(context, message);
        }
      });
      
      // Apply default section
      final settingsProvider = context.read<SettingsProvider>();
      if (settingsProvider.defaultSectionIndex != 0) {
         context.read<NavigationProvider>().setIndex(settingsProvider.defaultSectionIndex);
      }
      
      // Request initial focus on Bottom Bar
      // We perform a delayed request to ensure the widget tree is ready and nodes are attached.
      Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
              final nav = context.read<NavigationProvider>();
              if (nav.bottomBarFocusNode.canRequestFocus) {
                 nav.bottomBarFocusNode.requestFocus();
              }
          }
      });
    });
  }

  // ... (error notification method omitted but preserved if not overlapped, wait, I need to match StartLine carefully)
  // Actually I cannot skip lines inside snippet if I don't provide them.
  // I will just use StartLine/EndLine for the specific blocks.
  
  // I will do two edits. One for initState, one for build.
  // Wait, I can do one `replace_file_content` if I include the whole file or large chunk, but that's wasteful.
  // I'll do two chunks since the tool allows replacement chunks.
  
  // Actually, I'll just replace initState first.


  void _showErrorNotification(BuildContext context, String message) {
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black45)],
              border: Border.all(color: Colors.redAccent, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Error de Descarga', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                  onPressed: () => overlayEntry?.remove(),
                )
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry?.mounted ?? false) {
        overlayEntry?.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, _) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            
            if (navProvider.bottomBarFocusNode.hasFocus) {
               // Focus is on bottom bar, allow exit
               final shouldPop = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                     title: const Text('¿Salir de TVMax?'),
                     actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salir')),
                     ],
                  ),
               );
               if (shouldPop ?? false) {
                   if (context.mounted) Navigator.of(context).pop();
               }
            } else {
               // Focus is in content -> Returning to bottom bar
               navProvider.bottomBarFocusNode.requestFocus();
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: navProvider.currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: FocusScope(
            node: navProvider.bottomBarFocusNode,
            child: NavigationBar(
              selectedIndex: navProvider.currentIndex,
              onDestinationSelected: (index) {
                // Determine if we need to switch tab or just focus content
                bool shouldFocusContent = true;
                
                if (navProvider.currentIndex != index) {
                   navProvider.setIndex(index);
                }
                
                // Move focus to content (Up direction)
                if (shouldFocusContent) {
                   // Small delay to allow UI rebuild if switching tabs
                   Future.microtask(() {
                      if (context.mounted) {
                          FocusScope.of(context).focusInDirection(TraversalDirection.up);
                      }
                   });
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Programas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.newspaper_outlined),
                  selectedIcon: Icon(Icons.newspaper),
                  label: 'Noticias',
                ),
                NavigationDestination(
                  icon: Icon(Icons.movie_creation_outlined),
                  selectedIcon: Icon(Icons.movie_creation),
                  label: 'Series',
                ),
                NavigationDestination(
                  icon: Icon(Icons.videocam_outlined),
                  selectedIcon: Icon(Icons.videocam),
                  label: 'Documentales',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Favoritos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: 'Descargas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }
}
