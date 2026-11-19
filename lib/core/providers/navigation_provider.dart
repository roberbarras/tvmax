import 'package:flutter/material.dart';

/// Tab positions in the bottom bar, left to right.
class NavTab {
  static const live = 0;
  static const programs = 1;
  static const news = 2;
  static const series = 3;
  static const documentaries = 4;
  static const favorites = 5;
  static const downloads = 6;
  static const settings = 7;
}

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  
  final FocusScopeNode bottomBarFocusNode = FocusScopeNode();

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
