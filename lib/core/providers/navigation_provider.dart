import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every top-level tab. The declaration order is the default order in the bar
/// and also the (fixed) order of the screens inside the IndexedStack.
enum AppTab {
  programs('Programas', Icons.home_outlined, Icons.home),
  live('Directo', Icons.live_tv_outlined, Icons.live_tv),
  news('Noticias', Icons.newspaper_outlined, Icons.newspaper),
  series('Series', Icons.movie_creation_outlined, Icons.movie_creation),
  documentaries('Documentales', Icons.videocam_outlined, Icons.videocam),
  favorites('Favoritos', Icons.favorite_outline, Icons.favorite),
  downloads('Descargas', Icons.download_outlined, Icons.download),
  settings('Ajustes', Icons.settings_outlined, Icons.settings);

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppTab(this.label, this.icon, this.selectedIcon);
}

class NavigationProvider extends ChangeNotifier {
  static const _keyTabOrder = 'tab_order';

  final SharedPreferences sharedPreferences;

  NavigationProvider({required this.sharedPreferences}) {
    _order = _loadOrder();
  }

  late List<AppTab> _order;

  /// Tabs in the order shown in the bottom bar (user-customisable).
  List<AppTab> get order => List.unmodifiable(_order);

  AppTab _current = AppTab.programs;
  AppTab get currentTab => _current;

  final FocusScopeNode bottomBarFocusNode = FocusScopeNode();

  void setTab(AppTab tab) {
    if (_current != tab) {
      _current = tab;
      notifyListeners();
    }
  }

  /// Moves a tab in the bar. Indices follow [ReorderableListView.onReorder].
  void moveTab(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex || oldIndex < 0 || oldIndex >= _order.length) return;
    final tab = _order.removeAt(oldIndex);
    _order.insert(newIndex.clamp(0, _order.length), tab);
    sharedPreferences.setStringList(_keyTabOrder, _order.map((t) => t.name).toList());
    notifyListeners();
  }

  void resetOrder() {
    _order = List.of(AppTab.values);
    sharedPreferences.remove(_keyTabOrder);
    notifyListeners();
  }

  List<AppTab> _loadOrder() {
    final saved = sharedPreferences.getStringList(_keyTabOrder);
    if (saved == null) return List.of(AppTab.values);

    final order = <AppTab>[];
    for (final name in saved) {
      for (final tab in AppTab.values) {
        if (tab.name == name && !order.contains(tab)) order.add(tab);
      }
    }
    // Tabs added in later versions go at their default relative spot: the end.
    for (final tab in AppTab.values) {
      if (!order.contains(tab)) order.add(tab);
    }
    return order;
  }
}
