import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/entities/content_source.dart';
import '../../domain/entities/program.dart';
import '../../domain/usecases/get_programs.dart';

import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../core/utils/concurrency_helper.dart';

/// RTVE television programs, with RTVE favorites first.
class RtveProvider extends ChangeNotifier {
  final GetPrograms getPrograms;
  final FavoritesProvider favoritesProvider;

  RtveProvider({
    required this.getPrograms,
    required this.favoritesProvider,
  }) {
    favoritesProvider.addListener(_onFavoritesChanged);
  }

  int _currentPage = 0;
  bool _hasMore = true;

  List<Program> _allPrograms = [];
  List<Program> programs = [];
  bool isLoading = false;
  Failure? failure;
  String _currentQuery = '';

  bool _isLoadingBackground = false;

  void _onFavoritesChanged() {
    _applyFilter();
    notifyListeners();
  }

  Future<void> fetchPrograms({bool loadMore = false}) async {
    if (isLoading) return;
    if (loadMore && !_hasMore) return;

    isLoading = true;
    if (!loadMore) {
      _currentPage = 0;
      _hasMore = true;
      failure = null;
      _isLoadingBackground = false; 
      
      final localFavs = favoritesProvider.getFavoritesBySource(ContentSource.rtve);
      _allPrograms = List.from(localFavs);
      programs = List.from(_allPrograms);
    }
    notifyListeners();

    final result = await getPrograms(GetProgramsParams(
      page: loadMore ? _currentPage + 1 : 0,
      source: ContentSource.rtve,
    ));

    result.fold(
      (l) {
        failure = l;
        isLoading = false;
      },
      (r) {
        if (loadMore) {
           _currentPage++;
           
           final existingIds = _allPrograms.map((p) => p.id).toSet();
           final newItems = r.where((p) => !existingIds.contains(p.id)).toList();
           _allPrograms.addAll(newItems);
        } else {
           // Initial load merge
           final favIds = _allPrograms.map((p) => p.id).toSet();
           final newItems = r.where((p) => !favIds.contains(p.id)).toList();
           
           _allPrograms.addAll(newItems);
           _currentPage = 0;
        }
        
        if (r.isEmpty) {
          _hasMore = false;
        }
        
        _applyFilter();
        
        isLoading = false;
        notifyListeners();

        if (!loadMore && _hasMore && !_isLoadingBackground) {
           _fetchAllPagesInBackground();
        }
      },
    );
  }

  Future<void> _fetchAllPagesInBackground() async {
    _isLoadingBackground = true;
    LoggerService().debug('Starting background fetch of RTVE programs...');
    
    while (_hasMore && _isLoadingBackground) {
      await Future.delayed(ConcurrencyHelper.getBackgroundFetchDelay());
      
      final result = await getPrograms(GetProgramsParams(
        page: _currentPage + 1,
        source: ContentSource.rtve,
      ));
      
      result.fold(
        (l) {
          LoggerService().debug('Background fetch RTVE error: ${l.message}');
          _isLoadingBackground = false;
        },
        (r) {
          if (r.isEmpty) {
            _hasMore = false;
            _isLoadingBackground = false;
          } else {
            _currentPage++;
            
            final existingIds = _allPrograms.map((p) => p.id).toSet();
            final newItems = r.where((p) => !existingIds.contains(p.id)).toList();
            
            _allPrograms.addAll(newItems);
            _applyFilter();
            notifyListeners(); 
          }
        },
      );
    }
    LoggerService().debug('Background fetch of RTVE programs completed.');
  }

  @override
  void dispose() {
    favoritesProvider.removeListener(_onFavoritesChanged);
    _isLoadingBackground = false;
    super.dispose();
  }

  void searchPrograms(String query) {
    _currentQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    // 1. Filter
    List<Program> filtered;
    if (_currentQuery.isEmpty) {
      filtered = List.from(_allPrograms);
    } else {
      final lowerQuery = _currentQuery.toLowerCase();
      filtered = _allPrograms.where((p) => 
        p.title.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    // 2. Sort by Favorites
    filtered.sort((a, b) {
      final favA = favoritesProvider.isFavorite(a.id);
      final favB = favoritesProvider.isFavorite(b.id);
      if (favA && !favB) return -1;
      if (!favA && favB) return 1;
      return 0;
    });

    programs = filtered;
  }
}
