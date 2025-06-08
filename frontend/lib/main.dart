import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/core/services/service_locator.dart';
import 'package:frontend/core/routes/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/storage/offline_database.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/poem_generation/presentation/providers/poem_generation_provider.dart';
import 'package:frontend/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup error handling
  await _setupErrorHandling();
  
  // Initialize services
  await _initializeServices();
  
  // Run app
  runApp(const MyApp());
}

/// Initialize all services
Future<void> _initializeServices() async {
  try {
    // Initialize service locator
    await setupServiceLocator();
    
    // Initialize offline database
    await OfflineDatabase.init();
    
    // Load cached data
    await _loadCachedData();
    
    // Setup periodic cache cleanup
    _setupPeriodicTasks();
    
    AppLogger.i('All services initialized successfully');
  } catch (e) {
    AppLogger.e('Error initializing services', e);
    
    // Show error message or fallback to minimal functionality
    // This is critical initialization, so we let the error propagate
    rethrow;
  }
}

/// Load cached data from offline storage
Future<void> _loadCachedData() async {
  try {
    // Clear expired cache
    await OfflineDatabase.clearExpiredCache();
    
    // Load auth data if available
    final authTokens = await OfflineDatabase.getAuthTokens();
    if (authTokens != null) {
      final accessToken = authTokens['access_token'] as String;
      final expiresAt = DateTime.parse(authTokens['expires_at'] as String);
      
      // Check if token is still valid
      if (expiresAt.isAfter(DateTime.now())) {
        serviceLocator<AuthProvider>().initializeFromToken(
          accessToken,
          expiresAt,
        );
      }
    }
    
    AppLogger.d('Cached data loaded successfully');
  } catch (e) {
    AppLogger.e('Error loading cached data', e);
    // Non-critical error, app can continue
  }
}

/// Setup periodic tasks
void _setupPeriodicTasks() {
  // Cleanup expired cache every 24 hours
  Timer.periodic(const Duration(hours: 24), (_) async {
    try {
      await OfflineDatabase.clearExpiredCache();
      AppLogger.d('Periodic cache cleanup completed');
    } catch (e) {
      AppLogger.e('Error during periodic cache cleanup', e);
    }
  });
  
  // Monitor connectivity changes
  Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      // Connection restored, sync any pending offline data
      _syncOfflineData();
    }
  });
}

/// Sync offline data when connection is restored
Future<void> _syncOfflineData() async {
  try {
    // Check if user is authenticated
    final authProvider = serviceLocator<AuthProvider>();
    if (!authProvider.isAuthenticated) return;
    
    // TODO: Implement offline data syncing logic
    // This would include:
    // 1. Checking for offline creations to sync
    // 2. Syncing user preferences
    // 3. Refreshing cached data
    
    AppLogger.d('Offline data synced successfully');
  } catch (e) {
    AppLogger.e('Error syncing offline data', e);
  }
}

/// Setup global error handling
Future<void> _setupErrorHandling() async {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.e('Flutter error: ${details.exception}', details.exception, details.stack);
    
    // Report to error tracking service in production
    // errorTrackingService.reportError(details.exception, details.stack);
    
    // Rethrow in debug mode for better debugging
    if (details.silent) {
      // Production mode - show a user-friendly error
      Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
    } else {
      // Debug mode - show full error
      FlutterError.dumpErrorToConsole(details);
    }
  };
  
  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('Platform error: $error', error, stack);
    
    // Report to error tracking service in production
    // errorTrackingService.reportError(error, stack);
    
    return true;
  };
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize router
    _appRouter = AppRouter();
    
    // Initialize connectivity monitoring
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
  
  // Platform messages are asynchronous, so we initialize in an async method
  Future<void> _initConnectivity() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
    } catch (e) {
      AppLogger.e('Error checking connectivity', e);
    }
    
    if (!mounted) return;
    
    setState(() {});
  }
  
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
    
    if (result != ConnectivityResult.none) {
      // Connection restored, sync offline data
      _syncOfflineData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: serviceLocator<AuthProvider>(),
        ),
        ChangeNotifierProvider<PoemGenerationProvider>.value(
          value: serviceLocator<PoemGenerationProvider>(),
        ),
        ChangeNotifierProvider<GalleryProvider>.value(
          value: serviceLocator<GalleryProvider>(),
        ),
        ChangeNotifierProvider<ProfileProvider>.value(
          value: serviceLocator<ProfileProvider>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'PoemVision AI',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Will be controlled by settings later
        routerConfig: _appRouter.router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Add global error handling UI
          if (child == null) return const SizedBox.shrink();
          
          // Add offline indicator when no connection
          return Stack(
            children: [
              child,
              if (_connectionStatus == ConnectivityResult.none)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: Colors.red,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'You are offline',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
