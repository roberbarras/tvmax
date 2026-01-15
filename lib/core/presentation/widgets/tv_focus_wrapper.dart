import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressDown;
  final double scaleFactor;
  final Color focusColor;
  final FocusNode? focusNode; // New optional parameter
  final FocusOnKeyCallback? onKey; // New optional onKey callback for custom handling

  const TvFocusWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.onLongPressDown,
    this.scaleFactor = 1.05,
    this.focusColor = Colors.orange,
    this.focusNode,
    this.onKey,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    // Only dispose if we created it
    if (widget.focusNode == null) {
       _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }


  Timer? _longPressTimer;
  bool _isLongPress = false;

  void _handleKeyDown(RawKeyEvent event) {
     if (event.repeat) return;
     
     if (_isValidKey(event.logicalKey)) {
        _isLongPress = false;
        _longPressTimer?.cancel();
        _longPressTimer = Timer(const Duration(milliseconds: 500), () {
           _isLongPress = true;
           widget.onLongPress?.call();
        });
     }
  }

  void _handleKeyUp(RawKeyEvent event) {
      if (_isValidKey(event.logicalKey)) {
         _longPressTimer?.cancel();
         
         if (!_isLongPress) {
            widget.onTap();
         }
      }
  }
  
  bool _isValidKey(LogicalKeyboardKey key) {
    // Only intercept Select/Enter/Space for Tap/LongPress logic
    // We do NOT intercept Arrow keys, allowing native navigation to work 100%
    return key == LogicalKeyboardKey.select || 
           key == LogicalKeyboardKey.enter ||
           key == LogicalKeyboardKey.numpadEnter ||
           key == LogicalKeyboardKey.space || 
           key == LogicalKeyboardKey.gameButtonA;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Focus(
        focusNode: _focusNode,
        onKey: (node, event) {
          // 0. Custom External Logic (e.g. Grid Navigation)
          if (widget.onKey != null) {
              final result = widget.onKey!(node, event);
              if (result == KeyEventResult.handled || result == KeyEventResult.skipRemainingHandlers) {
                  return result;
              }
          }

          if (event is RawKeyDownEvent) {
             // 1. Global Shortcuts for Navigation (Menu Key -> Jump Bottom)
             if (event.logicalKey == LogicalKeyboardKey.contextMenu || 
                 event.logicalKey == LogicalKeyboardKey.keyM) {
                 widget.onLongPressDown?.call(); // Reuse listener for "Jump Bottom"
                 return KeyEventResult.handled;
             }

             // 2. Handle Tap/LongPress keys
             if (_isValidKey(event.logicalKey)) {
                 _handleKeyDown(event);
                 return KeyEventResult.handled;
             }
          } else if (event is RawKeyUpEvent) {
             if (_isValidKey(event.logicalKey)) {
                _handleKeyUp(event);
                return KeyEventResult.handled;
             }
          }
          // 3. Allow everything else (Arrows) to pass through naturally
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            return ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                foregroundDecoration: _isFocused
                    ? BoxDecoration(
                        border: Border.all(color: widget.focusColor, width: 3),
                        borderRadius: BorderRadius.circular(8), 
                      )
                    : null,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}
