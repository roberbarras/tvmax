import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'core/database/database_helper.dart';
import 'features/episodes/data/datasources/episodes_local_data_source.dart';
import 'features/episodes/data/datasources/episodes_remote_data_source.dart';
import 'features/episodes/data/repositories/episodes_repository_impl.dart';
import 'features/episodes/domain/repositories/episodes_repository.dart';
import 'features/episodes/domain/usecases/get_episodes.dart';
import 'features/episodes/domain/usecases/get_streaming_url.dart';
import 'features/episodes/presentation/providers/episodes_provider.dart';
import 'features/player/data/datasources/player_local_data_source.dart';
import 'features/player/data/repositories/player_repository_impl.dart';
import 'features/player/domain/repositories/player_repository.dart';
import 'features/player/domain/usecases/download_video.dart';
import 'features/player/domain/usecases/play_video.dart';
import 'features/player/presentation/providers/downloads_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/favorites/presentation/providers/favorites_provider.dart';
import 'features/programs/data/datasources/programs_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/programs/data/datasources/programs_remote_data_source.dart';
import 'features/programs/data/repositories/programs_repository_impl.dart';
import 'features/programs/domain/repositories/programs_repository.dart';
import 'features/programs/domain/usecases/get_programs.dart';
import 'features/programs/presentation/providers/programs_provider.dart';
import 'features/programs/presentation/providers/news_provider.dart'; // Import NewsProvider
import 'features/programs/presentation/providers/series_provider.dart';
import 'features/programs/presentation/providers/documentaries_provider.dart';
import 'core/providers/navigation_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Programs
  // Provider
  sl.registerFactory(() => ProgramsProvider(getPrograms: sl(), favoritesProvider: sl()));
  sl.registerFactory(() => NewsProvider(getPrograms: sl(), favoritesProvider: sl())); // Register NewsProvider
  sl.registerFactory(() => SeriesProvider(getPrograms: sl(), favoritesProvider: sl())); // Register SeriesProvider
  sl.registerFactory(() => DocumentariesProvider(getPrograms: sl(), favoritesProvider: sl())); // Register DocumentariesProvider

  // Use cases
  sl.registerLazySingleton(() => GetPrograms(sl()));

  // Repository
  sl.registerLazySingleton<ProgramsRepository>(
    () => ProgramsRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProgramsRemoteDataSource>(
    () => ProgramsRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );
  sl.registerLazySingleton<ProgramsLocalDataSource>(
    () => ProgramsLocalDataSourceImpl(databaseHelper: sl()),
  );

  //! Features - Episodes
  // Provider
  sl.registerFactory(() => EpisodesProvider(
        getEpisodes: sl(),
        getStreamingUrl: sl(),
        playVideo: sl(),
        downloadVideo: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetEpisodes(sl()));
  sl.registerLazySingleton(() => GetStreamingUrl(sl()));

  // Repository
  sl.registerLazySingleton<EpisodesRepository>(
    () => EpisodesRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<EpisodesRemoteDataSource>(
    () => EpisodesRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );
  sl.registerLazySingleton<EpisodesLocalDataSource>(
    () => EpisodesLocalDataSourceImpl(databaseHelper: sl()),
  );

  //! Features - Player
  // Use cases
  sl.registerLazySingleton(() => PlayVideo(sl()));
  sl.registerLazySingleton(() => DownloadVideo(sl()));

  // Repository
  sl.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PlayerLocalDataSource>(
    () => PlayerLocalDataSourceImpl(),
  );

  // Downloads Provider
  sl.registerFactory(() => DownloadsProvider(
     playerLocalDataSource: sl(),
     settingsProvider: sl(), // Inject settings
  ));
  
  // SettingsProvider
  sl.registerLazySingleton(() => SettingsProvider(sharedPreferences: sl()));

  // Favorites Provider
  sl.registerLazySingleton(() => FavoritesProvider(dbHelper: sl()));

  // Navigation Provider
  sl.registerLazySingleton(() => NavigationProvider());

  //! Core
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
}
