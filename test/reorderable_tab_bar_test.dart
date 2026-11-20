import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvflix/core/presentation/widgets/reorderable_tab_bar.dart';
import 'package:tvflix/core/providers/navigation_provider.dart';

void main() {
  group('NavigationProvider', () {
    test('default order puts Programas first and Directo second', () async {
      SharedPreferences.setMockInitialValues({});
      final nav = NavigationProvider(sharedPreferences: await SharedPreferences.getInstance());
      expect(nav.order.take(2), [AppTab.programs, AppTab.live]);
      expect(nav.order.length, AppTab.values.length);
    });

    test('moveTab reorders and persists, following ReorderableListView semantics', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final nav = NavigationProvider(sharedPreferences: prefs);

      nav.moveTab(1, 0); // Directo to the front
      expect(nav.order.first, AppTab.live);

      nav.moveTab(0, 3); // dragging forward: newIndex counts the removed item
      expect(nav.order[2], AppTab.live);

      final reloaded = NavigationProvider(sharedPreferences: prefs);
      expect(reloaded.order, nav.order);
    });

    test('RTVE tab: after Documentales by default, appended to orders saved before it existed', () async {
      SharedPreferences.setMockInitialValues({});
      final fresh = NavigationProvider(sharedPreferences: await SharedPreferences.getInstance());
      expect(fresh.order.indexOf(AppTab.rtve), fresh.order.indexOf(AppTab.documentaries) + 1);

      final savedBeforeRtve = AppTab.values.where((t) => t != AppTab.rtve).map((t) => t.name).toList();
      SharedPreferences.setMockInitialValues({'tab_order': savedBeforeRtve});
      final upgraded = NavigationProvider(sharedPreferences: await SharedPreferences.getInstance());
      expect(upgraded.order.last, AppTab.rtve);
      expect(upgraded.order.toSet(), AppTab.values.toSet());
    });

    test('unknown or missing saved tabs are tolerated', () async {
      SharedPreferences.setMockInitialValues({
        'tab_order': ['series', 'does_not_exist', 'live'],
      });
      final nav = NavigationProvider(sharedPreferences: await SharedPreferences.getInstance());
      expect(nav.order.take(2), [AppTab.series, AppTab.live]);
      expect(nav.order.toSet(), AppTab.values.toSet());
    });
  });

  testWidgets('long press + drag moves a tab; a plain tap selects it', (tester) async {
    var tabs = List.of(AppTab.values);
    AppTab selected = AppTab.programs;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: ReorderableTabBar(
              tabs: tabs,
              selected: selected,
              onSelected: (tab) => setState(() => selected = tab),
              onReorder: (oldIndex, newIndex) => setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                tabs.insert(newIndex, tabs.removeAt(oldIndex));
              }),
            ),
          ),
        ),
      ),
    );

    // Tap selects
    await tester.tap(find.text('Noticias'));
    await tester.pump();
    expect(selected, AppTab.news);

    // Long press on "Directo" (2nd) and drag it left, past "Programas"
    final gesture = await tester.startGesture(tester.getCenter(find.text('Directo')));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tabs.first, AppTab.live);
    expect(tabs[1], AppTab.programs);
  });
}
