import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../injection_container.dart';
import '../../../episodes/presentation/pages/episodes_screen.dart';
import '../../../episodes/presentation/providers/episodes_provider.dart';
import '../providers/documentaries_provider.dart';
import '../widgets/program_card.dart';

class DocumentariesScreen extends StatefulWidget {
  const DocumentariesScreen({super.key});

  @override
  State<DocumentariesScreen> createState() => _DocumentariesScreenState();
}

class _DocumentariesScreenState extends State<DocumentariesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DocumentariesProvider>();
      if (provider.docs.isEmpty) {
         provider.fetchDocs();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Timer? _debounce;

  void _onSearchChanged(String query) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      
      _debounce = Timer(const Duration(milliseconds: 300), () {
          context.read<DocumentariesProvider>().searchDocs(query);
      });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<DocumentariesProvider>().fetchDocs(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
             hintText: 'Buscar documentales...',
             border: InputBorder.none,
             prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
             _onSearchChanged(value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DocumentariesProvider>().fetchDocs();
            },
          ),
        ],
      ),
      body: Consumer<DocumentariesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.docs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.failure != null && provider.docs.isEmpty) {
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
                      provider.fetchDocs();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.docs.isEmpty) {
            return const Center(child: Text('No hay documentales disponibles.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchDocs();
            },
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.docs.length,
                    itemBuilder: (context, index) {
                      final program = provider.docs[index];
                      return ProgramCard(
                        program: program,
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
                  ),
                ),
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
