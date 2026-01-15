import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Generic Widget to handle Manual Focus Grid Navigation
class ManualFocusGrid<T> extends StatefulWidget {
  final List<T> items;
  final int crossAxisCount;
  final double itemAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final ScrollController scrollController;
  final Widget Function(BuildContext, int, T, FocusNode) itemBuilder;
  final VoidCallback? onExitUp;
  final VoidCallback? onExitDown;

  const ManualFocusGrid({
    Key? key,
    required this.items,
    required this.crossAxisCount,
    required this.itemAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.scrollController,
    required this.itemBuilder,
    this.onExitUp,
    this.onExitDown,
  }) : super(key: key);

  @override
  State<ManualFocusGrid> createState() => ManualFocusGridState<T>();
}

class ManualFocusGridState<T> extends State<ManualFocusGrid<T>> {
  final Map<int, FocusNode> _focusNodes = {};
  int _focusedIndex = 0;
  Timer? _edgeHoldTimer;
  bool _isEdgeLongPressTriggered = false;

  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _edgeHoldTimer?.cancel();
    super.dispose();
  }

  FocusNode _getNode(int index) {
    if (!_focusNodes.containsKey(index)) {
       _focusNodes[index] = FocusNode(debugLabel: 'GridItem $index');
       _focusNodes[index]!.addListener(() {
          if (_focusNodes[index]!.hasFocus) {
             _focusedIndex = index;
             _scrollToEnsureVisible(index);
          }
       });
    }
    return _focusNodes[index]!;
  }
  
  void _scrollToEnsureVisible(int index) {
      if (!mounted) return;
      
      if (!widget.scrollController.hasClients) return;
      
      final position = widget.scrollController.position;
      final viewportHeight = position.viewportDimension;
      final currentScroll = position.pixels;

      final cols = widget.crossAxisCount;
      final row = index ~/ cols;
      
      final screenWidth = MediaQuery.of(context).size.width; 
      final availableWidth = screenWidth - 32; // Assuming 16px padding on sides
      final itemWidth = (availableWidth - (cols - 1) * widget.crossAxisSpacing) / cols;
      final itemHeight = itemWidth / widget.itemAspectRatio;
      final rowHeight = itemHeight + widget.mainAxisSpacing;
      
      final itemTop = row * rowHeight + 16; 
      final itemBottom = itemTop + rowHeight - widget.mainAxisSpacing;
      
      double targetScroll = currentScroll;
      
      if (itemTop < currentScroll + 5) {
         targetScroll = itemTop - 16;
      } else if (itemBottom > currentScroll + viewportHeight - 5) {
         targetScroll = itemBottom - viewportHeight + 16; 
      }
      
      if (targetScroll < 0) targetScroll = 0;
      if (targetScroll > position.maxScrollExtent) targetScroll = position.maxScrollExtent;
      
      if ((targetScroll - currentScroll).abs() > 10) {
          widget.scrollController.animateTo(
             targetScroll,
             duration: const Duration(milliseconds: 250),
             curve: Curves.easeOut,
          );
      }
  }

  KeyEventResult _onKeyHandler(FocusNode node, RawKeyEvent event, int index) {
     final cols = widget.crossAxisCount;
     final count = widget.items.length;
     
     if (event is RawKeyDownEvent) {
          if (event.repeat) return KeyEventResult.ignored;

          final key = event.logicalKey;
          
          if (key == LogicalKeyboardKey.arrowUp) {
              if (index - cols < 0) {
                  _isEdgeLongPressTriggered = false;
                  _edgeHoldTimer?.cancel();
                  _edgeHoldTimer = Timer(const Duration(milliseconds: 500), () {
                      _isEdgeLongPressTriggered = true;
                      widget.onExitUp?.call(); 
                  });
                  return KeyEventResult.handled;
              } else {
                  _navigateTo(index - cols);
                  return KeyEventResult.handled;
              }
          }
          
          if (key == LogicalKeyboardKey.arrowDown) {
               if (index + cols >= count) {
                   _isEdgeLongPressTriggered = false;
                   _edgeHoldTimer?.cancel();
                   _edgeHoldTimer = Timer(const Duration(milliseconds: 500), () {
                       _isEdgeLongPressTriggered = true;
                       widget.onExitDown?.call();
                   });
                   return KeyEventResult.handled;
               } else {
                   _navigateTo(index + cols);
                   return KeyEventResult.handled;
               }
          }

          if (key == LogicalKeyboardKey.arrowRight) {
             int next = (index + 1) % cols == 0 
                ? index - cols + 1 
                : index + 1;
             if (next >= count) next = (index ~/ cols) * cols; 
             if (next >= count) next = count - 1;
             
             _navigateTo(next);
             return KeyEventResult.handled;
          }
          
          if (key == LogicalKeyboardKey.arrowLeft) {
              int next = index % cols == 0
                 ? index + cols - 1
                 : index - 1;
              if (next >= count) next = count - 1;
              _navigateTo(next);
              return KeyEventResult.handled;
          }
          
     } else if (event is RawKeyUpEvent) {
          final key = event.logicalKey;
          
          if (key == LogicalKeyboardKey.arrowUp) {
              if (_edgeHoldTimer != null && _edgeHoldTimer!.isActive) {
                  _edgeHoldTimer!.cancel();
                  if (!_isEdgeLongPressTriggered) {
                      _wrapToBottom(index, cols, count);
                  }
                  return KeyEventResult.handled;
              }
          }
          
          if (key == LogicalKeyboardKey.arrowDown) {
              if (_edgeHoldTimer != null && _edgeHoldTimer!.isActive) {
                  _edgeHoldTimer!.cancel();
                  if (!_isEdgeLongPressTriggered) {
                      _wrapToTop(index, cols);
                  }
                  return KeyEventResult.handled;
              }
          }
     }
     
     return KeyEventResult.ignored;
  }
  
  void _navigateTo(int index) {
     if (index >= 0 && index < widget.items.length) {
        _getNode(index).requestFocus();
     }
  }
  
  void _wrapToBottom(int index, int cols, int count) {
       final col = index % cols;
       final totalRows = (count / cols).ceil();
       int candidate = ((totalRows - 1) * cols) + col;
       if (candidate >= count) candidate -= cols;
       _navigateTo(candidate);
  }
  
  void resetFocus() {
      _focusedIndex = 0;
      _scrollToEnsureVisible(0);
      _getNode(0).requestFocus();
  }
  
  void restoreFocus() {
      if (_focusedIndex >= widget.items.length) _focusedIndex = 0;
      _scrollToEnsureVisible(_focusedIndex);
      _getNode(_focusedIndex).requestFocus();
  }

  void _wrapToTop(int index, int cols) {
      final col = index % cols;
      _navigateTo(col); 
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
       controller: widget.scrollController,
       padding: const EdgeInsets.all(16),
       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
           crossAxisCount: widget.crossAxisCount,
           childAspectRatio: widget.itemAspectRatio,
           crossAxisSpacing: widget.crossAxisSpacing,
           mainAxisSpacing: widget.mainAxisSpacing,
       ),
       itemCount: widget.items.length,
       itemBuilder: (context, index) {
          final item = widget.items[index];
          // We wrap the item builder to inject OnKey
          return Focus(
             onKey: (node, event) => _onKeyHandler(node, event, index),
             child: Builder(
                builder: (context) {
                   // We actually need to pass the node and onKey down?
                   // The ProgramCard expects focusNode and onKey.
                   // So we should just pass the node to the builder.
                   return widget.itemBuilder(context, index, item, _getNode(index));
                }
             ),
          );
       },
    );
  }
}
