import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../providers/navigation_provider.dart';

/// Bottom tab bar whose tabs can be reordered: long-press a tab, then drag it.
/// Not used on Android TV, where a D-pad would make dragging confusing.
class ReorderableTabBar extends StatelessWidget {
  final List<AppTab> tabs;
  final AppTab selected;
  final ValueChanged<AppTab> onSelected;
  final void Function(int oldIndex, int newIndex) onReorder;

  const ReorderableTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    required this.onReorder,
  });

  static const double _minItemWidth = 76;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Color.alphaBlend(scheme.primary.withOpacity(0.05), scheme.surfaceContainer),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = math.max(_minItemWidth, constraints.maxWidth / tabs.length);
              return ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                itemCount: tabs.length,
                onReorder: onReorder,
                proxyDecorator: (child, index, animation) => Material(
                  color: Colors.transparent,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(tab),
                    index: index,
                    child: SizedBox(
                      width: itemWidth,
                      child: _TabItem(
                        tab: tab,
                        selected: tab == selected,
                        onTap: () => onSelected(tab),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? scheme.secondaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
