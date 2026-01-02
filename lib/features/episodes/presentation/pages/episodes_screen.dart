import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../injection_container.dart';
import '../../../../core/error/failures.dart';
import '../../../programs/domain/entities/program.dart';
import '../providers/episodes_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
// import '../widgets/episode_detail_dialog.dart'; // To be implemented
import '../../../../features/player/presentation/providers/downloads_provider.dart';
import '../../../../features/player/presentation/pages/video_player_screen.dart';
import '../widgets/availability_banner.dart';

class EpisodesScreen extends StatefulWidget {
  final Program program;

  const EpisodesScreen({super.key, required this.program});

  @override
  State<EpisodesScreen> createState() => _EpisodesScreenState();
}

class _EpisodesScreenState extends State<EpisodesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EpisodesProvider>().fetchEpisodes(widget.program.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.title),
      ),
      body: Consumer<EpisodesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.failure != null) {
             return Center(child: Text(provider.failure!.message));
          }

          if (provider.episodes.isEmpty) {
            return const Center(child: Text('No hay episodios disponibles.'));
          }

          return ListView.builder(
            itemCount: provider.episodes.length,
            itemBuilder: (context, index) {
              final episode = provider.episodes[index];
              return ListTile(
                leading: Stack(
                  children: [
                    episode.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: episode.imageUrl!,
                            width: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey),
                            errorWidget: (context, url, err) => const Icon(Icons.error),
                          )
                        : const SizedBox(
                            width: 100,
                            height: 56, // Approx standard list tile image height
                            child: Icon(Icons.movie),
                          ),
                    // Availability Banner for this episode
                    if (provider.episodeAvailability.containsKey(episode.id))
                         Positioned(
                           top: 0,
                           right: 0, 
                           child: _buildAvailabilityBanner(provider.episodeAvailability[episode.id]),
                         ),
                  ],
                ),
                title: Text(episode.title),
                subtitle: Text(episode.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                   // Show dialog
                   _showEpisodeOptions(context, episode);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvailabilityBanner(int? statusCode) {
    if (statusCode == null) return const SizedBox.shrink();

    String text;
    Color color;

    if (statusCode == 200) {
      text = 'OK';
      color = Colors.green;
    } else if (statusCode == 403 || statusCode == 401) {
      text = 'PREMIUM';
      color = Colors.red;
    } else if (statusCode == 404) {
      text = 'NO DISP.';
      color = Colors.red;
    } else {
      text = 'ERR $statusCode';
      color = Colors.orange;
    }
    
    return AvailabilityBanner(text: text, color: color);
  }

  void _showEpisodeOptions(BuildContext context, dynamic episode) { // Keep dynamic or Episode if imported
    // Capture providers from the valid context BEFORE showing the dialog
    final episodesProvider = Provider.of<EpisodesProvider>(context, listen: false);
    final downloadsProvider = Provider.of<DownloadsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(episode.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(episode.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(dialogContext);
               _playVideoInternal(context, episode, episodesProvider);
            },
            child: const Text('Ver Ahora'),
          ),
          ElevatedButton(
             onPressed: () {
                 Navigator.pop(dialogContext);
                 // We use the captured providers here
                 // ERROR FIX: Use 'context' (parent) not 'dialogContext' because dialog is popped
                 _startDownloadWithProvider(context, episode, episodesProvider, downloadsProvider);
             },
             child: const Text('Descargar'),
          )
        ],
      ),
    );
  }

  Future<void> _playVideoInternal(BuildContext context, dynamic episode, EpisodesProvider episodesProvider) async {
    try {
      final url = await episodesProvider.fetchStreamingUrl(episode.id);
      
      if (url != null) {
         if (!mounted) return;
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (_) => VideoPlayerScreen(
                url: url, 
                title: episode.title,
                episodeId: episode.id,
             ),
           ),
         );
      } else {
        // Check for specific failures
        if (episodesProvider.failure is PremiumContentFailure) {
           _showPremiumErrorDialog(context);
        } else if (episodesProvider.failure != null) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: ${episodesProvider.failure!.message}')),
           );
        }
      }
    } catch (e) {
      print('Error playing video: $e');
    }
  }

  void _showPremiumErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contenido Premium'),
        content: const Text(
          'Este contenido no está disponible con tu suscripción actual (o falta la cookie).\n\n'
          'Intenta actualizar tu cookie en Ajustes o prueba con contenido gratuito (últimos episodios).'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          TextButton(
             onPressed: () {
               Navigator.pop(context);
               context.read<NavigationProvider>().setIndex(6); // Settings (was 4, now 6)
               Navigator.popUntil(context, (route) => route.isFirst);
             },
             child: const Text('Ir a Ajustes'),
          )
        ],
      ),
    );
  }

  Future<void> _startDownloadWithProvider(
      BuildContext context, 
      dynamic episode, 
      EpisodesProvider episodesProvider, 
      DownloadsProvider downloadsProvider
  ) async {
      try {
        final url = await episodesProvider.fetchStreamingUrl(episode.id);
        
        if (url != null) {
           final fileName = '${widget.program.title} - ${episode.title}';
           downloadsProvider.addDownload(episode.id, fileName, url);
           
           if (!mounted) return;
           _showDownloadNotification(context, widget.program.title, episode.title);
        }
      } catch (e) {
        print('Error starting download: $e');
      }
  }

  void _showDownloadNotification(BuildContext context, String programTitle, String episodeTitle) {
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
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black45)],
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Icon(Icons.download_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Descarga iniciada', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$programTitle\n$episodeTitle', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      overlayEntry?.remove();
                      // Navigate to Downloads tab
                      context.read<NavigationProvider>().setIndex(5); // Index 5 is Downloads
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('VER DESCARGAS'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(overlayEntry);

    // Remove after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry?.mounted ?? false) {
        overlayEntry?.remove();
      }
    });
  }
}
