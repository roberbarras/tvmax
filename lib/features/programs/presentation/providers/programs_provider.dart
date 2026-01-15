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
      
      // 1. Initial Load: Start with Favorites
      final localFavs = favoritesProvider.favorites;
      _allPrograms = List.from(localFavs);
      
      // Reset displayed list immediately to show favorites
      _applyFilter();
    }
    notifyListeners();

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
           _mergeNewItems(r);
        } else {
           // Initial load complete.
           _currentPage = 0;
           _mergeNewItems(r);
        }
        
        if (r.isEmpty) {
          _hasMore = false;
        }
        
        isLoading = false;
        notifyListeners();

        // Trigger background fetch if we have more and not already loading background
        if (!loadMore && _hasMore && !_isLoadingBackground) {
           _fetchAllPagesInBackground();
        }
      },
    );
  }
  
  void _mergeNewItems(List<Program> newItems) {
      // Logic:
      // 1. We have _allPrograms which starts as [Fav1, Fav2...]
      // 2. We receive new items from API.
      // 3. We must append ONLY those that are NOT already in _allPrograms.
      // 4. Since _allPrograms already contains Favorites, we just check against existing IDs.
      
      final existingIds = _allPrograms.map((p) => p.id).toSet();
      final uniqueNewItems = newItems.where((p) => !existingIds.contains(p.id)).toList();
      
      _allPrograms.addAll(uniqueNewItems);
      _applyFilter();
  }

  Future<void> _fetchAllPagesInBackground() async {
    _isLoadingBackground = true;
    LoggerService().debug('Starting background fetch of programs...');
    
    while (_hasMore && _isLoadingBackground) {
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
            _mergeNewItems(r);
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
    List<Program> filtered;
    
    if (_currentQuery.isEmpty) {
      // Default View: Favorites First (Implicitly handled by _allPrograms order)
      // _allPrograms is constructed as [Favorites + API Results]
      // We just need to make sure API results didn't duplicate favorites.
      // AND we need to make sure if a Favorite was added/removed, logical order is kept?
      // Actually, if a user ADDS a favorite, we want it to jump to top?
      // Yes, _onFavoritesChanged triggers this.
      
      // Re-construct logic to ensure Favorites are ALWAYS at top if query is empty
      final favs = favoritesProvider.favorites;
      final favIds = favs.map((p) => p.id).toSet();
      
      // Non-favs from our accumulated list
      final nonFavs = _allPrograms.where((p) => !favIds.contains(p.id)).toList();
      
      programs = [...favs, ...nonFavs];
      
      // Update _allPrograms to reflect this canonical order? 
      // It's safer to keep _allPrograms as the source of truth for "Fetched Data", 
      // but displayed 'programs' list is the projection.
    } else {
      final lowerQuery = _currentQuery.toLowerCase();
      // Search: Filter matches, then sort favorites to top
      final matches = _allPrograms.where((p) => 
        p.title.toLowerCase().contains(lowerQuery)
      ).toList();
      
      matches.sort((a, b) {
        final favA = favoritesProvider.isFavorite(a.id);
        final favB = favoritesProvider.isFavorite(b.id);
        if (favA && !favB) return -1;
        if (!favA && favB) return 1;
        return 0;
      });
      
      programs = matches;
    }
  }
}
