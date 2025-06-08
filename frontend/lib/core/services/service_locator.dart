import 'package:get_it/get_it.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:frontend/features/poem_generation/domain/services/poem_service.dart';
import 'package:frontend/features/poem_generation/presentation/providers/poem_generation_provider.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

/// Service locator instance
final GetIt serviceLocator = GetIt.instance;

/// Setup service locator
Future<void> setupServiceLocator() async {
  // Register providers
  serviceLocator.registerLazySingleton<AuthProvider>(() => AuthProvider());
  
  serviceLocator.registerLazySingleton<GalleryProvider>(() => GalleryProvider());
  
  // Register services
  serviceLocator.registerLazySingleton<PoemService>(() => PoemServiceImpl());
  
  serviceLocator.registerLazySingleton<PoemGenerationProvider>(
    () => PoemGenerationProvider(poemService: serviceLocator<PoemService>()),
  );
  
  serviceLocator.registerLazySingleton<ProfileProvider>(() => ProfileProvider());
}
