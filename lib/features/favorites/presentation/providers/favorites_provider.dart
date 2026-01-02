import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../programs/domain/entities/program.dart';

class FavoritesProvider extends ChangeNotifier {
  final DatabaseHelper dbHelper;

  FavoritesProvider({required this.dbHelper});

  List<Program> _favorites = [];
  List<Program> get favorites => _favorites;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();
    
    final db = await dbHelper.database;
    final result = await db.query('favorites', orderBy: 'addedAt DESC');
    
    _favorites = result.map((json) {
      return Program(
        id: json['id'] as String,
        title: json['title'] as String,
        description: '', // Not stored in favs for now, generic description
        imageUrlHorizontal: null, 
        imageUrlVertical: json['imageUrl'] as String?,
        channel: json['channel'] as String? ?? 'Desconocido',
        categoryId: json['categoryId'] as String?,
      );
    }).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favorites.any((p) => p.id == id);
  }

  // Helper helper to filter favorites
  List<Program> getFavoritesByCategoryId(String? categoryId) {
     if (categoryId == null) return [];
     // Filter loosely potentially? Or strict equality
     return _favorites.where((p) => p.categoryId == categoryId).toList();
  }

  Future<void> toggleFavorite(Program program) async {
    final db = await dbHelper.database;
    
    if (isFavorite(program.id)) {
      await db.delete('favorites', where: 'id = ?', whereArgs: [program.id]);
      _favorites.removeWhere((p) => p.id == program.id);
    } else {
      await db.insert('favorites', {
        'id': program.id,
        'title': program.title,
        'imageUrl': program.imageUrlVertical,
        'channel': program.channel,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
        'categoryId': program.categoryId, // Ensure Program has this populated when passed!
      });
      _favorites.add(program);
      
      // Update local list safely
      _favorites.removeWhere((p) => p.id == program.id);
      _favorites.insert(0, program); // Newest first
    }
    notifyListeners();
  }
}
