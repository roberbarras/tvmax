import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/episode.dart';
import '../../domain/usecases/get_episodes.dart';
import '../../domain/usecases/get_streaming_url.dart';
import '../../../player/domain/usecases/play_video.dart';
import '../../../player/domain/usecases/download_video.dart';
import '../../../../core/utils/logger_service.dart';

/// The heavy lifter for the Episodes screen.
///
/// Responsibilities:
/// - Fetches episodes (with pagination support).
/// - Silently loads ALL pages in the background to ensure smooth scrolling.
/// - Checks "Availability" (Free vs Premium) for every single episode in parallel batches.
/// - Manages the state of the "Play" action.
class EpisodesProvider extends ChangeNotifier {
  final GetEpisodes getEpisodes;
  final GetStreamingUrl getStreamingUrl;
  final PlayVideo playVideo;
  final DownloadVideo downloadVideo;

  EpisodesProvider({
    required this.getEpisodes,
    required this.getStreamingUrl,
    required this.playVideo,
    required this.downloadVideo,
  });

  List<Episode> _allEpisodes = []; // Store all
  List<Episode> episodes = [];
  bool isLoading = false;
  Failure? failure;
  
  String? currentStreamingUrl;
  bool isUrlLoading = false;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingBackground = false;
  String? _currentFormatId;

  Future<void> fetchEpisodes(String formatId) async {
    // Reset if new format
    if (_currentFormatId != formatId) {
       _currentFormatId = formatId;
       isLoading = true;
       episodes = [];
       _allEpisodes = [];
       _currentPage = 0;
       _hasMore = true;
       failure = null;
       _hasMore = true;
       failure = null;
       episodeAvailability.clear();
       _isLoadingBackground = false; // Stop prev loop if any
       notifyListeners();
    } else if (isLoading) {
       return;
    }

    final result = await getEpisodes(GetEpisodesParams(formatId: formatId, page: 0));

    List<Episode>? episodesToCheck;

    result.fold(
      (l) {
        failure = l;
        isLoading = false;
        notifyListeners();
      },
      (r) {
        _allEpisodes = r;
        episodes = r; // Update displayed list
        _currentPage = 0;
        isLoading = false;
        
        if (r.isEmpty) {
          _hasMore = false;
        } else {
           episodesToCheck = r;
           // Start background fetch ONLY if we got data and haven't finished
           _hasMore = true;
           if (!_isLoadingBackground) { // Avoid double start
              _fetchAllPagesInBackground(formatId);
           }
        }
        notifyListeners();
      },
    );

    if (episodesToCheck != null) {
       // Process in batches of 5
       int batchSize = 5;
       for (var i = 0; i < episodesToCheck!.length; i += batchSize) {
          if (_currentFormatId != formatId) break; // Check context validity

          final end = (i + batchSize < episodesToCheck!.length) ? i + batchSize : episodesToCheck!.length;
          final batch = episodesToCheck!.sublist(i, end);

          // Execute batch in parallel
          await Future.wait(
             batch.map((ep) => checkAvailability(ep.id))
          );
          
          // Small throttle between batches to be safe
          await Future.delayed(const Duration(milliseconds: 100));
       }
    }
  }

  Map<String, int> episodeAvailability = {};

  /// "Probes" an episode to see if we can play it.
  ///
  /// Instead of trusting metadata (which lies), we try to fetch the streaming URL.
  /// If the server says 403, we know it's Premium.
  /// If it says 200, it's Free.
  /// We cache the result in [episodeAvailability] map to avoid spamming the server.
  Future<void> checkAvailability(String episodeId) async {
    if (episodeAvailability.containsKey(episodeId)) return; // Already checked

    // Probe the URL to check status code
    final result = await getStreamingUrl(GetStreamingUrlParams(contentId: episodeId));
    
    result.fold(
      (l) {
        if (l is PremiumContentFailure) {
           episodeAvailability[episodeId] = l.statusCode ?? 403;
        } else if (l is ServerFailure) {
           episodeAvailability[episodeId] = l.statusCode ?? 500;
        } else {
           episodeAvailability[episodeId] = 500;
        }
        notifyListeners();
      },
      (r) {
        episodeAvailability[episodeId] = 200;
        notifyListeners();
      },
    );
  }

  Future<void> _fetchAllPagesInBackground(String formatId) async {
    _isLoadingBackground = true;
    LoggerService().debug('Starting background fetch of episodes for $formatId...');
    
    while (_hasMore && _isLoadingBackground && _currentFormatId == formatId) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await getEpisodes(GetEpisodesParams(formatId: formatId, page: _currentPage + 1));
      
      result.fold(
        (l) {
           LoggerService().debug('Background episodes error: ${l.message}');
           _isLoadingBackground = false;
        },
        (r) {
           if (r.isEmpty) {
             _hasMore = false;
             _isLoadingBackground = false;
           } else {
             _currentPage++;
             _allEpisodes.addAll(r);
             episodes = List.from(_allEpisodes); // Update display
             notifyListeners();
           }
        },
      );
    }
    LoggerService().debug('Background fetch of episodes completed.');
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _isLoadingBackground = false;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<String?> fetchStreamingUrl(String contentId) async {
    isUrlLoading = true;
    notifyListeners();

    final result = await getStreamingUrl(GetStreamingUrlParams(contentId: contentId));

    String? url;
    result.fold(
      (l) {
        failure = l;
        isUrlLoading = false;
        notifyListeners(); // Notify so UI can see failure
      },
      (r) {
        currentStreamingUrl = r;
        url = r;
        isUrlLoading = false;
      },
    );
    notifyListeners();
    return url;
  }

  Future<void> playEpisode(String url) async {
    await playVideo(PlayVideoParams(url: url));
  }

  Future<void> downloadEpisode(String url, String fileName) async {
    await downloadVideo(DownloadVideoParams(url: url, fileName: fileName));
  }
}
