import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/routes/app_router.dart';
import 'package:frontend/core/services/service_locator.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Setup service locator
    await setupServiceLocator();
    
    // Run app
    runApp(const PoemVisionApp());
  } catch (e, stackTrace) {
    // Log any initialization errors
    AppLogger.e('Error initializing app', e, stackTrace);
    rethrow;
  }
}

/// Main application widget
class PoemVisionApp extends StatelessWidget {
  const PoemVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the AuthProvider to the entire app
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => serviceLocator.get<AuthProvider>(),
        ),
        // Add other providers as needed
      ],
      child: MaterialApp.router(
        title: 'PoemVision AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Default to light theme
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // Apply common layout properties to all screens
          return MediaQuery(
            // Set default text scaling to avoid layout issues
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}
