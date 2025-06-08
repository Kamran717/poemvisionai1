import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/storage/local_storage.dart';
import 'package:frontend/features/auth/domain/services/auth_service.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/gallery/domain/services/gallery_service.dart';
import 'package:frontend/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:frontend/features/poem_generation/domain/services/poem_service.dart';
import 'package:frontend/features/poem_generation/presentation/providers/poem_generation_provider.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

/// Service locator instance
final GetIt serviceLocator = GetIt.instance;

/// Setup service locator
Future<void> setupServiceLocator() async {
  // Register SharedPreferences and LocalStorage
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);
  serviceLocator.registerSingleton<LocalStorage>(LocalStorage(sharedPreferences));
  
  // Register services
  serviceLocator.registerLazySingleton<AuthService>(
    () => AuthServiceImpl(apiBaseUrl: 'https://api.poemvision.ai'),
  );
  
  serviceLocator.registerLazySingleton<GalleryService>(
    () => GalleryServiceImpl(),
  );
  
  // Register providers
  serviceLocator.registerLazySingleton<AuthProvider>(
    () => AuthProvider(authService: serviceLocator<AuthService>()),
  );
  
  serviceLocator.registerLazySingleton<GalleryProvider>(
    () => GalleryProvider(galleryService: serviceLocator<GalleryService>()),
  );
  
  // Register services
  serviceLocator.registerLazySingleton<PoemService>(() => PoemServiceImpl());
  
  serviceLocator.registerLazySingleton<PoemGenerationProvider>(
    () => PoemGenerationProvider(poemService: serviceLocator<PoemService>()),
  );
  
  // Create a profile service first if needed
  serviceLocator.registerLazySingleton<ProfileProvider>(() => ProfileProvider());
}
