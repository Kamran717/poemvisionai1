import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'config/app_router.dart';

void main() {
  runApp(const PoemVisionApp());
}

class PoemVisionApp extends StatelessWidget {
  const PoemVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp.router(
        title: 'PoemVision AI',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: false,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
