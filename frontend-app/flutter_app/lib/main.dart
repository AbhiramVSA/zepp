import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/theme_notifier.dart';
import 'features/authentication/repository/auth_repository.dart';
import 'features/authentication/viewmodel/auth_viewmodel.dart';
import 'features/home/repository/history_repository.dart';
import 'features/home/view/home_view.dart';
import 'features/home/viewmodel/history_viewmodel.dart';
import 'features/transcribe/repository/transcribe_repository.dart';
import 'features/transcribe/viewmodel/transcribe_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final TranscribeRepository transcribeRepository =
      TranscribeRepository(backendWsUrl: backendWsUrl);
  final authRepository = AuthRepository();
  final historyRepository = HistoryRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(
          create: (context) => HistoryViewModel(
            historyRepository,
            context.read<AuthViewModel>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => TranscribeViewModel(transcribeRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeNotifier themeNotifier = context.watch<ThemeNotifier>();
    const Color seed = Colors.indigo;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Transcribe',
      themeMode: themeNotifier.mode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        fontFamily: 'Roboto',
      ),
      home: const HomeView(),
    );
  }
}
