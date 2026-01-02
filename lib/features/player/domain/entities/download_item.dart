enum DownloadStatus { queued, downloading, completed, failed }

class DownloadItem {
  final String id;
  final String title;
  final String url;
  DownloadStatus status;
  double progress; // 0.0 to 1.0 (for now 0 or 1 until we parse output)
  String? outputConfirmPath;
  int? sessionId;

  DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.sessionId,
  });
}
