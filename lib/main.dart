import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';
import 'features/player/presentation/providers/downloads_provider.dart';
import 'features/programs/presentation/providers/programs_provider.dart';
import 'features/programs/presentation/providers/news_provider.dart';
import 'features/programs/presentation/providers/series_provider.dart';
import 'features/programs/presentation/providers/documentaries_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/favorites/presentation/providers/favorites_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'core/providers/navigation_provider.dart';
import 'injection_container.dart' as di;

import 'core/utils/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('[Main] Initializing MediaKit...');
    MediaKit.ensureInitialized();
  } catch (e) {
    print('[Main] MediaKit Init Failed: $e');
  }

  try {
    print('[Main] Initializing DI...');
    await di.init();
  } catch (e) {
    print('[Main] DI Init Failed: $e');
  }
  
  await LoggerService().init();

  // Pre-load critical data to avoid modify-during-build errors
  try {
     print('[Main] Loading Settings...');
     await di.sl<SettingsProvider>().loadSettings();
     print('[Main] Settings Loaded.');
  } catch (e) {
     print('[Main] Settings Load Failed: $e');
  }

  try {
     print('[Main] Loading Favorites...');
     di.sl<FavoritesProvider>().loadFavorites(); 
  } catch (e) {
     print('[Main] Favorites Load Failed: $e');
  }
  
  print('[Main] Running App...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => di.sl<ProgramsProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<NewsProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<SeriesProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<DocumentariesProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<DownloadsProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<SettingsProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<FavoritesProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<NavigationProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'TVMax',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF141414),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          // cardTheme: CardTheme(
          //   color: const Color(0xFF1E1E1E),
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          // ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
