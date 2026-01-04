import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/program.dart';
import '../../domain/usecases/get_programs.dart';

import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../../core/utils/logger_service.dart';

class DocumentariesProvider extends ChangeNotifier {
  final GetPrograms getPrograms;
  final FavoritesProvider favoritesProvider;

  DocumentariesProvider({
    required this.getPrograms,
    required this.favoritesProvider,
  }) {
    favoritesProvider.addListener(_onFavoritesChanged);
  }

  int _currentPage = 0;
  bool _hasMore = true;

  List<Program> _allDocs = [];
  List<Program> docs = [];
  bool isLoading = false;
  Failure? failure;
  String _currentQuery = '';

  bool _isLoadingBackground = false;

  void _onFavoritesChanged() {
    _applyFilter();
    notifyListeners();
  }

  Future<void> fetchDocs({bool loadMore = false}) async {
    if (isLoading) return;
    if (loadMore && !_hasMore) return;

    isLoading = true;
    if (!loadMore) {
      _currentPage = 0;
      _hasMore = true;
      failure = null;
      _isLoadingBackground = false; 
      
      final localFavs = favoritesProvider.getFavoritesByCategoryId(AppConstants.documentariesCategoryId);
      _allDocs = List.from(localFavs);
      docs = List.from(_allDocs);
    }
    notifyListeners();

    final result = await getPrograms(GetProgramsParams(
      page: loadMore ? _currentPage + 1 : 0,
      mainChannelId: AppConstants.documentariesMainChannelId,
      categoryId: AppConstants.documentariesCategoryId,
    ));

    result.fold(
      (l) {
        failure = l;
        isLoading = false;
      },
      (r) {
        if (loadMore) {
           _currentPage++;
           
           final existingIds = _allDocs.map((p) => p.id).toSet();
           final newItems = r.where((p) => !existingIds.contains(p.id)).toList();
           _allDocs.addAll(newItems);
        } else {
           final favIds = _allDocs.map((p) => p.id).toSet();
           final newItems = r.where((p) => !favIds.contains(p.id)).toList();
           
           _allDocs.addAll(newItems);
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
    LoggerService().debug('Starting background fetch of docs...');
    
    while (_hasMore && _isLoadingBackground) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await getPrograms(GetProgramsParams(
        page: _currentPage + 1,
        mainChannelId: AppConstants.documentariesMainChannelId,
        categoryId: AppConstants.documentariesCategoryId,
      ));
      
      result.fold(
        (l) {
          LoggerService().debug('Background fetch docs error: ${l.message}');
          _isLoadingBackground = false;
        },
        (r) {
          if (r.isEmpty) {
            _hasMore = false;
            _isLoadingBackground = false;
          } else {
            _currentPage++;
            
            final existingIds = _allDocs.map((p) => p.id).toSet();
            final newItems = r.where((p) => !existingIds.contains(p.id)).toList();
            
            _allDocs.addAll(newItems);
            _applyFilter();
            notifyListeners(); 
          }
        },
      );
    }
    LoggerService().debug('Background fetch of docs completed.');
  }

  @override
  void dispose() {
    favoritesProvider.removeListener(_onFavoritesChanged);
    _isLoadingBackground = false;
    super.dispose();
  }

  void searchDocs(String query) {
    _currentQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    // 1. Filter
    List<Program> filtered;
    if (_currentQuery.isEmpty) {
      filtered = List.from(_allDocs);
    } else {
      final lowerQuery = _currentQuery.toLowerCase();
      filtered = _allDocs.where((p) => 
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

    docs = filtered;
  }
}
