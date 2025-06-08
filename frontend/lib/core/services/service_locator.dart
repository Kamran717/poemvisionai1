import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/network_error_handler.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/domain/services/auth_service.dart';
import 'package:frontend/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:frontend/features/gallery/domain/services/gallery_service.dart';
import 'package:frontend/features/poem_generation/presentation/providers/poem_generation_provider.dart';
import 'package:frontend/features/poem_generation/domain/services/poem_service.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:frontend/features/profile/domain/services/profile_service.dart';

/// Get the service locator instance
final GetIt serviceLocator = GetIt.instance;

/// Setup service locator
Future<void> setupServiceLocator() async {
  // Register core services
  _registerNetworkServices();
  
  // Register domain services
  _registerDomainServices();
  
  // Register providers
  _registerProviders();
}

/// Register network services
void _registerNetworkServices() {
  // Register Dio
  serviceLocator.registerLazySingleton<Dio>(() => Dio());
  
  // Register Connectivity
  serviceLocator.registerLazySingleton<Connectivity>(() => Connectivity());
  
  // Register NetworkErrorHandler
  serviceLocator.registerLazySingleton<NetworkErrorHandler>(
    () => const NetworkErrorHandler(),
  );
  
  // Register ApiClient
  serviceLocator.registerLazySingleton<ApiClient>(() => ApiClient(
    baseUrl: ApiConstants.baseUrl,
    dio: serviceLocator<Dio>(),
    connectivity: serviceLocator<Connectivity>(),
    errorHandler: serviceLocator<NetworkErrorHandler>(),
  ));
}

/// Register domain services
void _registerDomainServices() {
  // Register AuthService
  serviceLocator.registerLazySingleton<AuthService>(() => AuthService(
    apiClient: serviceLocator<ApiClient>(),
  ));
  
  // Register GalleryService
  serviceLocator.registerLazySingleton<GalleryService>(() => GalleryService(
    apiClient: serviceLocator<ApiClient>(),
  ));
  
  // Register PoemService
  serviceLocator.registerLazySingleton<PoemService>(() => PoemService(
    apiClient: serviceLocator<ApiClient>(),
  ));
  
  // Register ProfileService
  serviceLocator.registerLazySingleton<ProfileService>(() => ProfileService(
    apiClient: serviceLocator<ApiClient>(),
  ));
}

/// Register providers
void _registerProviders() {
  // Register AuthProvider
  serviceLocator.registerLazySingleton<AuthProvider>(() => AuthProvider(
    authService: serviceLocator<AuthService>(),
  ));
  
  // Register GalleryProvider
  serviceLocator.registerLazySingleton<GalleryProvider>(() => GalleryProvider(
    galleryService: serviceLocator<GalleryService>(),
  ));
  
  // Register PoemGenerationProvider
  serviceLocator.registerLazySingleton<PoemGenerationProvider>(() => PoemGenerationProvider(
    poemService: serviceLocator<PoemService>(),
  ));
  
  // Register ProfileProvider
  serviceLocator.registerLazySingleton<ProfileProvider>(() => ProfileProvider(
    profileService: serviceLocator<ProfileService>(),
  ));
}
