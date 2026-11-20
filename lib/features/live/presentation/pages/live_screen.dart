import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/tv_focus_wrapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../injection_container.dart';
import '../../../player/presentation/pages/video_player_screen.dart';
import '../../data/live_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final LiveService _service = sl<LiveService>();
  String? _loadingChannelId;

  static const _brandColors = {
    '5a6a165a7ed1a834493ebf6a': Color(0xFFE65100), // Antena 3
    '5a6a172c7ed1a834493ebf6b': Color(0xFFAD1457), // laSexta
    '1694255': Color(0xFFC62828), // 24h
    '5466990': Color(0xFF6A1B9A), // Clan
  };

  Future<void> _open(LiveChannel channel) async {
    if (_loadingChannelId != null) return; // Ignore extra OK presses while loading
    setState(() => _loadingChannelId = channel.id);

    try {
      final stream = await _service.getStream(channel);
      if (!mounted) return;
      final title = stream.programTitle == null || stream.programTitle!.isEmpty
          ? channel.name
          : '${channel.name} · ${stream.programTitle}';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            url: stream.url,
            title: title,
            episodeId: 'live_${channel.id}',
            isLive: true,
            source: channel.source,
          ),
        ),
      );
    } catch (e) {
      print('[LiveScreen] Error opening ${channel.name}: $e');
      if (!mounted) return;
      final blocked = e is ServerException && (e.statusCode == 403 || e.statusCode == 404);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is DrmProtectedException
              ? 'El directo de ${channel.name} es contenido protegido, no disponible.'
              : blocked
                  ? 'El directo de ${channel.name} no está disponible (¿fuera de España?).'
                  : 'No se pudo abrir el directo de ${channel.name}. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingChannelId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 32,
            runSpacing: 32,
            children: [
              for (final channel in LiveService.channels)
                _ChannelCard(
                  channel: channel,
                  color: _brandColors[channel.id] ?? Colors.orange,
                  loading: _loadingChannelId == channel.id,
                  onTap: () => _open(channel),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final LiveChannel channel;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ChannelCard({
    required this.channel,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 160,
      child: TvFocusWrapper(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.55)],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    channel.name,
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Row(
                    children: const [
                      Icon(Icons.circle, size: 10, color: Colors.white),
                      SizedBox(width: 6),
                      Text('EN DIRECTO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (loading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
