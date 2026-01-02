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
                TextField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '/home/user/Downloads',
                    suffixIcon: Icon(Icons.folder),
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Autenticación (Cookies)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Pega aquí el valor de la header "Cookie" para acceder al contenido:'),
                const SizedBox(height: 8),
                TextField(
                  controller: _cookieController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'AMCVS_...; ...',
                    suffixIcon: Icon(Icons.security),
                  ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
