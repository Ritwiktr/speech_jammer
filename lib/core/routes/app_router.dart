import 'package:flutter/material.dart';
import '../../features/presentation/screens/home_screen.dart';

class AppRouter {
  static const String home = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }
}

