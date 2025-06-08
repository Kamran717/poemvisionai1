import 'package:flutter/material.dart';
import 'package:frontend/core/routes/app_router.dart';
import 'package:frontend/core/services/service_locator.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';

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
    return MaterialApp.router(
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
    );
  }
}
