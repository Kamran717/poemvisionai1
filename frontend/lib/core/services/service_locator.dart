import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/local_storage.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/auth/domain/services/auth_service.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/poem_generation/domain/services/poem_service.dart';
import 'package:frontend/features/poem_generation/presentation/providers/poem_generation_provider.dart';
import 'package:frontend/features/gallery/domain/services/gallery_service.dart';
import 'package:frontend/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:frontend/features/profile/domain/services/profile_service.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

/// Global ServiceLocator instance
final GetIt serviceLocator = GetIt.instance;

/// Initialize all service dependencies
Future<void> setupServiceLocator() async {
  // External services
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);
  
  serviceLocator.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(),
  );
  
  // Network
  serviceLocator.registerSingleton<Dio>(
    Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(seconds: ApiConstants.connectTimeout),
        receiveTimeout: Duration(seconds: ApiConstants.receiveTimeout),
        sendTimeout: Duration(seconds: ApiConstants.sendTimeout),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    ),
  );
  
  // Storage
  serviceLocator.registerSingleton<LocalStorage>(
    LocalStorage(serviceLocator<SharedPreferences>()),
  );
  
  serviceLocator.registerSingleton<SecureStorage>(
    SecureStorage(serviceLocator<FlutterSecureStorage>()),
  );
  
  // API Clients
  serviceLocator.registerSingleton<ApiClient>(
    ApiClient(serviceLocator<Dio>()),
  );
  
  // Auth Services
  serviceLocator.registerSingleton<AuthService>(
    AuthService(
      serviceLocator<ApiClient>(),
      serviceLocator<SecureStorage>(),
    ),
  );
  
  // Poem Services
  serviceLocator.registerSingleton<PoemService>(
    PoemService(serviceLocator<ApiClient>()),
  );
  
  // Gallery Services
  serviceLocator.registerSingleton<GalleryService>(
    GalleryService(serviceLocator<ApiClient>()),
  );
  
  // Profile Services
  serviceLocator.registerSingleton<ProfileService>(
    ProfileService(serviceLocator<ApiClient>()),
  );
  
  // Providers
  serviceLocator.registerSingleton<AuthProvider>(
    AuthProvider(serviceLocator<AuthService>()),
  );
  
  serviceLocator.registerSingleton<PoemGenerationProvider>(
    PoemGenerationProvider(serviceLocator<PoemService>()),
  );
  
  serviceLocator.registerSingleton<GalleryProvider>(
    GalleryProvider(serviceLocator<GalleryService>()),
  );
  
  serviceLocator.registerSingleton<ProfileProvider>(
    ProfileProvider(serviceLocator<ProfileService>()),
  );
  
  // Add more services as needed
  // Repository layer
  _setupRepositories();
  
  // Application business logic / Use cases
  _setupUseCases();
  
  // ViewModels/BLoCs/Cubits
  _setupViewModels();
}

/// Setup repositories
void _setupRepositories() {
  // Example:
  // serviceLocator.registerSingleton<UserRepository>(
  //   UserRepositoryImpl(serviceLocator<ApiClient>()),
  // );
}

/// Setup use cases
void _setupUseCases() {
  // Example:
  // serviceLocator.registerSingleton<GetUserProfileUseCase>(
  //   GetUserProfileUseCase(serviceLocator<UserRepository>()),
  // );
}

/// Setup ViewModels/BLoCs/Cubits
void _setupViewModels() {
  // Example:
  // serviceLocator.registerFactory<UserProfileBloc>(
  //   () => UserProfileBloc(serviceLocator<GetUserProfileUseCase>()),
  // );
}
