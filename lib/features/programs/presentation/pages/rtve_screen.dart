import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../injection_container.dart';
import '../../../episodes/presentation/pages/episodes_screen.dart';
import '../../../episodes/presentation/providers/episodes_provider.dart';
import '../providers/rtve_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../widgets/program_card.dart';
import '../../../../core/presentation/widgets/manual_focus_grid.dart';

/// The RTVE catalog: television programs from the public RTVE API.
class RtveScreen extends StatefulWidget {
  const RtveScreen({super.key});

  @override
  State<RtveScreen> createState() => _RtveScreenState();
}

class _RtveScreenState extends State<RtveScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ManualFocusGridState> _gridGlobalKey = GlobalKey(); 
  
  Timer? _searchHoldTimer;
  bool _isSearchLongPressTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RtveProvider>();
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
          context.read<RtveProvider>().searchPrograms(query);
      });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<RtveProvider>().fetchPrograms(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyRepeatEvent) return KeyEventResult.ignored;
            if (event is KeyDownEvent) {
               if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                   _isSearchLongPressTriggered = false;
                   _searchHoldTimer?.cancel();
                   _searchHoldTimer = Timer(const Duration(milliseconds: 500), () {
                       _isSearchLongPressTriggered = true;
                       _gridGlobalKey.currentState?.resetFocus();
                   });
                   return KeyEventResult.handled;
               }
               
               if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                   FocusScope.of(context).nextFocus();
                   return KeyEventResult.handled;
               }
            } else if (event is KeyUpEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_searchHoldTimer != null && _searchHoldTimer!.isActive) {
                        _searchHoldTimer!.cancel();
                        if (!_isSearchLongPressTriggered) {
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
               _gridGlobalKey.currentState?.restoreFocus();
            },
            decoration: const InputDecoration(
               hintText: 'Buscar en RTVE...',
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
              context.read<RtveProvider>().fetchPrograms();
            },
          ),
        ],
      ),
      body: Consumer<RtveProvider>(
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
                    onPressed: () {
                      provider.fetchPrograms();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.programs.isEmpty) {
            return const Center(child: Text('No hay programas de RTVE disponibles.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchPrograms();
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                const maxExtent = 200.0;
                const crossAxisSpacing = 16.0;
                const padding = 32.0; 
                
                final availableWidth = width - padding;
                int crossAxisCount = (availableWidth / (maxExtent + crossAxisSpacing)).ceil();
                if (crossAxisCount < 1) crossAxisCount = 1;

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
                      return ProgramCard(
                         program: program,
                         focusNode: focusNode,
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
