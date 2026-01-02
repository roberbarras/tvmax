import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/program.dart';
import '../../domain/usecases/get_programs.dart';

import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../../core/utils/logger_service.dart';

class SeriesProvider extends ChangeNotifier {
  final GetPrograms getPrograms;
  final FavoritesProvider favoritesProvider;

  SeriesProvider({
    required this.getPrograms,
    required this.favoritesProvider,
  }) {
    favoritesProvider.addListener(_onFavoritesChanged);
  }

  int _currentPage = 0;
  bool _hasMore = true;

  List<Program> _allSeries = [];
  List<Program> series = [];
  bool isLoading = false;
  Failure? failure;
  String _currentQuery = '';

  bool _isLoadingBackground = false;

  void _onFavoritesChanged() {
    _applyFilter();
    notifyListeners();
  }

  Future<void> fetchSeries({bool loadMore = false}) async {
    if (isLoading) return;
    if (loadMore && !_hasMore) return;

    isLoading = true;
    if (!loadMore) {
      _currentPage = 0;
      _hasMore = true;
      failure = null;
      _isLoadingBackground = false; 
      
      // Load favorites matching Series Category
      final localFavs = favoritesProvider.getFavoritesByCategoryId(AppConstants.seriesCategoryId);
      // Wait, if existing users don't have categoryId, they won't show up here?
      // Acceptable for new architecture. Old favs might appear in the mix or we assume null category = show everywhere?
      // Let's assume strict filtering for now as requested for "Stable" behavior.
      
      _allSeries = List.from(localFavs);
      series = List.from(_allSeries);
    }
    notifyListeners();

    final result = await getPrograms(GetProgramsParams(
      page: loadMore ? _currentPage + 1 : 0,
      mainChannelId: AppConstants.seriesMainChannelId,
      categoryId: AppConstants.seriesCategoryId,
    ));

    result.fold(
      (l) {
        failure = l;
        isLoading = false;
      },
      (r) {
        if (loadMore) {
           _currentPage++;
           
           final existingIds = _allSeries.map((p) => p.id).toSet();
           final newItems = r.where((p) => !existingIds.contains(p.id)).toList();
           _allSeries.addAll(newItems);
        } else {
           // Initial load merge
           final favIds = _allSeries.map((p) => p.id).toSet();
           final newItems = r.where((p) => !favIds.contains(p.id)).toList();
           
           _allSeries.addAll(newItems);
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
    LoggerService().debug('Starting background fetch of series...');
    
    while (_hasMore && _isLoadingBackground) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await getPrograms(GetProgramsParams(
        page: _currentPage + 1,
        mainChannelId: AppConstants.seriesMainChannelId,
        categoryId: AppConstants.seriesCategoryId,
      ));
      
      result.fold(
        (l) {
          LoggerService().debug('Background fetch series error: ${l.message}');
          _isLoadingBackground = false;
        },
        (r) {
          if (r.isEmpty) {
            _hasMore = false;
            _isLoadingBackground = false;
          } else {
            _currentPage++;
            
            final existingIds = _allSeries.map((p) => p.id).toSet();
            final newItems = r.where((p) => !existingIds.contains(p.id)).toList();
            
            _allSeries.addAll(newItems);
            _applyFilter();
            notifyListeners(); 
          }
        },
      );
    }
    LoggerService().debug('Background fetch of series completed.');
  }

  @override
  void dispose() {
    favoritesProvider.removeListener(_onFavoritesChanged);
    _isLoadingBackground = false;
    super.dispose();
  }

  void searchSeries(String query) {
    _currentQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    // 1. Filter
    List<Program> filtered;
    if (_currentQuery.isEmpty) {
      filtered = List.from(_allSeries);
    } else {
      final lowerQuery = _currentQuery.toLowerCase();
      filtered = _allSeries.where((p) => 
        p.title.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    // 2. Sort by Favorites - REMOVED per user request to keep API order
    // filtered.sort((a, b) {
    //   final favA = favoritesProvider.isFavorite(a.id);
    //   final favB = favoritesProvider.isFavorite(b.id);
    //   if (favA && !favB) return -1;
    //   if (!favA && favB) return 1;
    //   return 0;
    // });

    series = filtered;
  }
}
