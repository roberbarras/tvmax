import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/downloads_provider.dart';
import '../../domain/entities/download_item.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descargas')),
      body: Consumer<DownloadsProvider>(
        builder: (context, provider, child) {
          if (provider.downloads.isEmpty) {
            return const Center(child: Text('No hay descargas recientes.'));
          }

          return ListView.builder(
            itemCount: provider.downloads.length,
            itemBuilder: (context, index) {
              final item = provider.downloads[index];
              return ListTile(
                leading: _buildStatusIcon(item.status),
                title: Text(item.title),
                subtitle: Text(_getStatusText(item.status)),
                trailing: _buildTrailing(context, item, provider),
              );
            },
          );
        },
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context, DownloadItem item, DownloadsProvider provider) {
    if (item.status == DownloadStatus.downloading) {
       return Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           IconButton(
             icon: const Icon(Icons.close, color: Colors.red),
             onPressed: () => provider.cancelDownload(item.id),
           ),
           const SizedBox(width: 8),
           const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
         ],
       );
    } else if (item.status == DownloadStatus.failed) {
       return IconButton(
         icon: const Icon(Icons.refresh, color: Colors.orange),
         tooltip: 'Reintentar',
         onPressed: () => provider.retryDownload(item.id),
       );
    }
    return null;
  }

  Widget _buildStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return const Icon(Icons.hourglass_empty);
      case DownloadStatus.downloading:
        return const Icon(Icons.downloading);
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued: return 'En cola...';
      case DownloadStatus.downloading: return 'Descargando...';
      case DownloadStatus.completed: return 'Completado';
      case DownloadStatus.failed: return 'Error';
    }
  }
}
