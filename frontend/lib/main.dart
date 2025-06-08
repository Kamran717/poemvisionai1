import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/services/service_locator.dart';
import 'package:frontend/core/routes/app_router.dart';

import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:frontend/features/poem_generation/presentation/providers/poem_generation_provider.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('app_settings');
  await Hive.openBox('user_cache');
  await Hive.openBox('offline_data');

  await setupServiceLocator();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    final authProvider = serviceLocator<AuthProvider>();
    await authProvider.initializeAuthState();

    if (authProvider.isAuthenticated) {
      await serviceLocator<ProfileProvider>().fetchUserProfile();
    }
  } catch (e) {
    AppLogger.e('Error during initialization', e);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppRouter _appRouter;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = serviceLocator<AuthProvider>();
      bool isAuth = await authProvider.checkAuthentication();

      _appRouter = AppRouter.create(isAuthenticated: isAuth);

      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.e('Flutter error', details.exception, details.stack);
      };

      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        AppLogger.e('Platform error', error, stack);
        return true;
      };

      setState(() {
        _isInitialized = true;
      });
    } catch (e, stack) {
      AppLogger.e('Error initializing app', e, stack);
      _appRouter = AppRouter.create(isAuthenticated: false);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: serviceLocator<AuthProvider>(),
        ),
        ChangeNotifierProvider<ProfileProvider>.value(
          value: serviceLocator<ProfileProvider>(),
        ),
        ChangeNotifierProvider<GalleryProvider>.value(
          value: serviceLocator<GalleryProvider>(),
        ),
        ChangeNotifierProvider<PoemGenerationProvider>.value(
          value: serviceLocator<PoemGenerationProvider>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'PoemVision AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: _appRouter.router, // Make sure `router` getter exists in AppRouter
      ),
    );
  }
}
