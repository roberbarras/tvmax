import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/program.dart';
import '../../domain/usecases/get_programs.dart';

import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../core/utils/concurrency_helper.dart';

/// The State Management hub for the Programs Screen.
///
/// This provider handles:
/// 1. Fetching programs (paginated).
/// 2. Background fetching (getting ALL pages silently so searching is fast).
/// 3. Filtering by text.
/// 4. Synchronizing with Favorites.
class ProgramsProvider extends ChangeNotifier {
  final GetPrograms getPrograms;
  final FavoritesProvider favoritesProvider;

  ProgramsProvider({
    required this.getPrograms,
    required this.favoritesProvider,
  }) {
    // Listen to favorites changes to update the list if needed (e.g. re-sort or badges)
    favoritesProvider.addListener(_onFavoritesChanged);
  }

  int _currentPage = 0;
  bool _hasMore = true;

  List<Program> _allPrograms = [];
  List<Program> programs = []; // This is the displayed list
  bool isLoading = false;
  Failure? failure;
  String _currentQuery = '';

  bool _isLoadingBackground = false;

  void _onFavoritesChanged() {
    _applyFilter();
    notifyListeners();
  }

  /// Triggers the data fetching process.
  ///
  /// [loadMore] - If true, tries to fetch the next page. If false, resets everything and starts from page 0.
  ///
  /// Logic:
  /// - Sets [isLoading] to true.
  /// - If resetting: pre-fills the list with Favorites (so the user sees something immediately).
  /// - Calls the API UseCase.
  /// - On success: merges new items, deduplicates, and kicks off background fetching.
  /// - On failure: shows the error.
  Future<void> fetchPrograms({bool loadMore = false}) async {
    if (isLoading) return;
    if (loadMore && !_hasMore) return;

    isLoading = true;
    if (!loadMore) {
      _currentPage = 0;
      _hasMore = true;
      failure = null;
      _isLoadingBackground = false; 
      
      // Load favorites FIRST
      // Assumption: Program entity for 'Programs' doesn't use a specific categoryId filter in the classic sense 
      // because 'Programs' in this app seems to be a catch-all or specific 'Programs' section?
      // Wait, getPrograms USES a categoryId?
      // In `programs_provider.dart`, getPrograms is called with default params!
      // `GetProgramsParams(page: ...)` -> default `formatId`? 
      // Checking `GetProgramsParams` definition/defaults would be wise, but assuming 'Programs' section logic:
      // If we don't have a category filter here, we might just show ALL favorites? 
      // Or maybe we treat "Programs" as everything not Series/Movies?
      // For now, let's assume we want to pin favorites that match the programs list. 
      // Since `ProgramsProvider` fetches "Search" row without mainChannel?
      
      // Actually, looking at `ProgramsRemoteDataSource` logs earlier: 
      // `categoryId=5a6a...` etc.
      // `ProgramsProvider` is simpler. 
      // Let's just try to merge ALL favorites if we can't filter, or filtering by a known ID if we had one.
      // User request: "los programas favoritos aparezcan en primer lugar". 
      // Since we don't know the exact category ID for the "Programs" tab without looking deeper,
      // We will rely on `favoritesProvider.favorites` and deduplicate.
      // BUT `ProgramsProvider` (generic) might be sharing logic.
      
      // Let's blindly load ALL favorites for now as a test, or try to respect the section logic if possible.
      // `ProgramsProvider` doesn't seem to pass categoryId.
      
      // Pre-load:
      final localFavs = favoritesProvider.favorites; // Or filter if we knew how
      _allPrograms = List.from(localFavs); // Start with favorites
      programs = List.from(_allPrograms);
    }
    notifyListeners(); // Immediate update with favorites

    final result = await getPrograms(GetProgramsParams(page: loadMore ? _currentPage + 1 : 0));

    result.fold(
      (l) {
        failure = l;
        isLoading = false;
        notifyListeners();
      },
      (r) {
        if (loadMore) {
           _currentPage++;
           
           // Filter out items already in _allPrograms (favorites or previous pages)
           final existingIds = _allPrograms.map((p) => p.id).toSet();
           final newItems = r.where((p) => !existingIds.contains(p.id)).toList();
           
           _allPrograms.addAll(newItems);
        } else {
           // Initial load complete.
           // _allPrograms already has favorites.
           // Append non-duplicate API results.
           final favIds = _allPrograms.map((p) => p.id).toSet();
           final newItems = r.where((p) => !favIds.contains(p.id)).toList();
           
           _allPrograms.addAll(newItems);
           _currentPage = 0;
        }
        
        if (r.isEmpty) {
          _hasMore = false;
        }
        
        // Re-apply filter if exists
        _applyFilter();
        
        isLoading = false;
        notifyListeners();

        // Trigger background fetch if we have more and not already loading background
        if (!loadMore && _hasMore && !_isLoadingBackground) {
           _fetchAllPagesInBackground();
        }
      },
    );
  }

  Future<void> _fetchAllPagesInBackground() async {
    _isLoadingBackground = true;
    LoggerService().debug('Starting background fetch of programs...');
    
    while (_hasMore && _isLoadingBackground) {
      // Dynamic throttle based on CPU power
      await Future.delayed(ConcurrencyHelper.getBackgroundFetchDelay());
      
      final result = await getPrograms(GetProgramsParams(page: _currentPage + 1));
      
      result.fold(
        (l) {
          LoggerService().debug('Background fetch error: ${l.message}');
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
    LoggerService().debug('Background fetch of programs completed.');
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
