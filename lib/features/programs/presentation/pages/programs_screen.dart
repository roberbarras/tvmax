import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../injection_container.dart';
import '../../../episodes/presentation/pages/episodes_screen.dart';
import '../../../episodes/presentation/providers/episodes_provider.dart';
import '../providers/programs_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../widgets/program_card.dart';
import '../../../../core/presentation/widgets/manual_focus_grid.dart'; // New Import

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _gridFocusNode = FocusNode();
  // Update Type to Generic State
  final GlobalKey<ManualFocusGridState> _gridGlobalKey = GlobalKey(); 
  
  // Search Bar Hold Timer
  Timer? _searchHoldTimer;
  bool _isSearchLongPressTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    _searchFocusNode.addListener(() {
       print('[ProgramsScreen] Search Focus: ${_searchFocusNode.hasFocus}');
    });
    // Note: _gridFocusNode is somewhat legacy now but we keep it for reference or if we re-introduce wrapper
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProgramsProvider>();
      if (provider.programs.isEmpty) {
         provider.fetchPrograms();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchHoldTimer?.cancel();
    super.dispose();
  }

  Timer? _debounce;

  void _onSearchChanged(String query) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      
      _debounce = Timer(const Duration(milliseconds: 300), () {
          context.read<ProgramsProvider>().searchPrograms(query);
      });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ProgramsProvider>().fetchPrograms(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Focus(
          onKey: (node, event) {
            if (event is RawKeyDownEvent) {
               if (event.repeat) return KeyEventResult.ignored;

               if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                   print('[KeyDebug] Search: ArrowDown KeyDown');
                   _isSearchLongPressTriggered = false;
                   _searchHoldTimer?.cancel();
                   _searchHoldTimer = Timer(const Duration(milliseconds: 500), () {
                       _isSearchLongPressTriggered = true;
                       print('[KeyDebug] Search: Long Press Down -> Reset Focus to 0');
                       _gridGlobalKey.currentState?.resetFocus();
                   });
                   return KeyEventResult.handled;
               }
               
               if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                   FocusScope.of(context).nextFocus();
                   return KeyEventResult.handled;
               }
            } else if (event is RawKeyUpEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_searchHoldTimer != null && _searchHoldTimer!.isActive) {
                        _searchHoldTimer!.cancel();
                        if (!_isSearchLongPressTriggered) {
                            print('[KeyDebug] Search: Short Press Down -> Restore Grid Focus');
                            _gridGlobalKey.currentState?.restoreFocus(); 
                        }
                    }
                    return KeyEventResult.handled;
                }
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
               print('[KeyDebug] Search Submitted. Moving focus to Grid.');
               _gridGlobalKey.currentState?.restoreFocus();
            },
            decoration: const InputDecoration(
               hintText: 'Buscar programas...',
               border: InputBorder.none,
               prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
               _onSearchChanged(value);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProgramsProvider>().fetchPrograms();
            },
          ),
        ],
      ),
      body: Consumer<ProgramsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.programs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.failure != null && provider.programs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, size: 48, color: Colors.red),
                   const SizedBox(height: 16),
                   Text(provider.failure!.message),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: () => provider.fetchPrograms(),
                     child: const Text('Reintentar'),
                   ),
                ],
              ),
            );
          }

          if (provider.programs.isEmpty) {
            return const Center(child: Text('No hay programas disponibles.'));
          }

          return RefreshIndicator(
            onRefresh: () async => await provider.fetchPrograms(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                const maxExtent = 200.0;
                const crossAxisSpacing = 16.0;
                const padding = 32.0; 
                
                final availableWidth = width - padding;
                int crossAxisCount = (availableWidth / (maxExtent + crossAxisSpacing)).ceil();
                if (crossAxisCount < 1) crossAxisCount = 1;

                // Call the Generic Widget
                return ManualFocusGrid(
                   key: _gridGlobalKey,
                   items: provider.programs,
                   crossAxisCount: crossAxisCount,
                   itemAspectRatio: 0.7,
                   crossAxisSpacing: crossAxisSpacing,
                   mainAxisSpacing: 16.0,
                   scrollController: _scrollController,
                   onExitUp: () {
                      FocusScope.of(context).requestFocus(_searchFocusNode);
                   },
                   onExitDown: () {
                      final nav = context.read<NavigationProvider>();
                      if (nav.bottomBarFocusNode.canRequestFocus) {
                         nav.bottomBarFocusNode.requestFocus();
                      }
                   },
                   itemBuilder: (context, index, program, focusNode) {
                      // Note: We need to pass logic 'onKey' equivalent?
                      // The ManualFocusGrid handles the 'onKey' internally wrapper.
                      // But ProgramCard previously had logic?
                      // No, ProgramCard just accepted 'onKey' and passed it to focus wrapper.
                      // ManualFocusGrid calls the itemBuilder with a plain widget.
                      // Wait. ManualFocusGrid wraps the returned widget in a Focus(onKey:...).
                      // So `ProgramCard` doesn't need to handle onKey anymore if we wrap it differently?
                      // `ManualFocusGrid` implementation:
                      /*
                         return Focus(
                             onKey: ...
                             child: widget.itemBuilder(...)
                         );
                      */
                      // So the `itemBuilder` returns the child of `Focus`.
                      // `ProgramCard` has internal `TvFocusWrapper`.
                      // `TvFocusWrapper` handles Tap/LongPress.
                      // It also ignores arrow keys.
                      // So `ManualFocusGrid`'s Focus (parent) will receive Arrow Keys if child ignores them?
                      // Yes.
                      // So `ProgramCard` *just* needs `focusNode` to display focus state.
                      // It *does not* need `onKey` argument if we rely on parent Focus widget.
                      // However, `ProgramCard` constructor might require it?
                      // Let's check ProgramCard constructor.
                      // Ideally we just pass `focusNode` and let parent handle navigation.
                      
                      return ProgramCard(
                         program: program,
                         focusNode: focusNode,
                         // onKey: ... we should NOT pass it or pass null if possible?
                         // If ManualFocusGrid handles onKey, we don't need ProgramCard to handle it.
                         // But ProgramCard internal TvFocusWrapper might need it?
                         // TvFocusWrapper allows `onKey` to be optional.
                         // Let's pass a dummy or null if allowed.
                         // Checking ProgramCard signature...
                         onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (_) => ChangeNotifierProvider(
                                    create: (_) => sl<EpisodesProvider>(),
                                    child: EpisodesScreen(program: program),
                                 ),
                               ),
                             );
                         },
                      );
                   },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
