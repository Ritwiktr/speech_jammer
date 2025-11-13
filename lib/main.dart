import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'core/themes/app_theme.dart';
import 'core/themes/theme_controller.dart';
import 'features/presentation/bloc/speech_jammer_bloc.dart';
import 'features/application/speech_jammer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        BlocProvider(
          create: (context) => SpeechJammerBloc(
            speechJammerService: SpeechJammerService(),
          ),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Speech Jammer',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            onGenerateRoute: AppRouter.onGenerateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
