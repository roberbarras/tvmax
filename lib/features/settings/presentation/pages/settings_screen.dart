import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _cookieController = TextEditingController();
  final FocusNode _pathFocusNode = FocusNode();
  final FocusNode _cookieFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    if (!provider.isLoading) {
      _pathController.text = provider.downloadPath;
      _cookieController.text = provider.cookie;
    }
  }

  bool _isDataLoaded = false;

  @override
  void dispose() {
    _pathController.dispose();
    _cookieController.dispose();
    _pathFocusNode.dispose();
    _cookieFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Initial sync when data loads (only once)
          // This allows the user to modify the text afterwards without it being reset
          if (!_isDataLoaded) {
             _pathController.text = provider.downloadPath;
             _cookieController.text = provider.cookie;
             _isDataLoaded = true;
             // Force focus on Path input initially for TV
             WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pathFocusNode.canRequestFocus) {
                  _pathFocusNode.requestFocus();
                }
             });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  'Carpeta de Descargas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Escribe la ruta absoluta donde quieres guardar los vídeos:'),
                const SizedBox(height: 8),
                // Read-Only Display of Path
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                       const Icon(Icons.folder, color: Colors.orange),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           _pathController.text, 
                           style: const TextStyle(fontFamily: 'monospace'),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                     showDialog(
                       context: context, 
                       builder: (context) {
                          final tempController = TextEditingController(text: _pathController.text);
                          return AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Editar Ruta de Descarga', style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: tempController,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: '/storage/...',
                                hintStyle: TextStyle(color: Colors.white54),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                onPressed: () {
                                   setState(() {
                                      _pathController.text = tempController.text;
                                   });
                                   Navigator.pop(context);
                                },
                                child: const Text('Aceptar', style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          );
                       }
                     );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('EDITAR RUTA MANUALMENTE'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Por Defecto (Downloads)'),
                      onPressed: () {
                         setState(() {
                            _pathController.text = '/storage/emulated/0/Download';
                         });
                      },
                    ),
                    ActionChip(
                      label: const Text('Movies'),
                      onPressed: () {
                         setState(() {
                            _pathController.text = '/storage/emulated/0/Movies';
                         });
                      },
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Autenticación (Cookies)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Pega aquí el valor de la header "Cookie" para acceder al contenido:'),
                const SizedBox(height: 8),
                // Read-Only Display of Cookie
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                       const Icon(Icons.security, color: Colors.orange),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           _cookieController.text.isEmpty ? 'Sin cookies' : 'Cookies configuradas', 
                           style: const TextStyle(fontFamily: 'monospace', color: Colors.white70),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                     showDialog(
                       context: context, 
                       builder: (context) {
                          final tempController = TextEditingController(text: _cookieController.text);
                          return AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Editar Cookie', style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: tempController,
                              autofocus: true,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Pega aquí el valor de la cookie...',
                                hintStyle: TextStyle(color: Colors.white54),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                onPressed: () {
                                   setState(() {
                                      _cookieController.text = tempController.text;
                                   });
                                   Navigator.pop(context);
                                },
                                child: const Text('Aceptar', style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          );
                       }
                     );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('EDITAR COOKIE'),
                ),
                const SizedBox(height: 16),
                const Divider(height: 32),
                const Text(
                  'Sección Principal al Iniciar:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Consumer<SettingsProvider>(
                  builder: (context, provider, _) {
                    return DropdownButton<int>(
                      value: provider.defaultSectionIndex,
                      isExpanded: true,
                      dropdownColor: Colors.grey[900],
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Programas')),
                        DropdownMenuItem(value: 1, child: Text('Noticias')),
                        DropdownMenuItem(value: 2, child: Text('Series')),
                        DropdownMenuItem(value: 3, child: Text('Documentales')),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setDefaultSectionIndex(value);
                      },
                    );
                  }
                ),
                const Divider(height: 32),
                const Text(
                  'Preferencias de Reproducción:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Subtítulos por defecto:'),
                Consumer<SettingsProvider>(
                  builder: (context, provider, _) {
                    return DropdownButton<String>(
                      value: provider.defaultSubtitleLanguage,
                      isExpanded: true,
                      dropdownColor: Colors.grey[900],
                      items: const [
                        DropdownMenuItem(value: 'off', child: Text('Desactivados')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'en', child: Text('Inglés')),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setDefaultSubtitleLanguage(value);
                      },
                    );
                  }
                ),
                const SizedBox(height: 16),
                const Text('Calidad por defecto:'),
                Consumer<SettingsProvider>(
                  builder: (context, provider, _) {
                    return DropdownButton<String>(
                      value: provider.defaultQuality,
                      isExpanded: true,
                      dropdownColor: Colors.grey[900],
                      items: const [
                        DropdownMenuItem(value: 'auto', child: Text('Automática (Mejor disponible)')),
                        DropdownMenuItem(value: '1080', child: Text('1080p')),
                        DropdownMenuItem(value: '720', child: Text('720p')),
                        DropdownMenuItem(value: '480', child: Text('480p')), // Data saver
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setDefaultQuality(value);
                      },
                    );
                  }
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.setDownloadPath(_pathController.text);
                      provider.setCookie(_cookieController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configuración guardada.')),
                      );
                    },
                    child: const Text('Guardar'),
                  ),
                ),
                const SizedBox(height: 32), // Padding bottom for TV overscan
              ],
            ),
          );
        },
      ),
    );
  }
}
