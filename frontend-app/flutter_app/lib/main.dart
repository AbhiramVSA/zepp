import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'core/theme_notifier.dart';
import 'features/authentication/repository/auth_repository.dart';
import 'features/authentication/viewmodel/auth_viewmodel.dart';
import 'features/home/repository/history_repository.dart';
import 'features/home/view/home_view.dart';
import 'features/home/viewmodel/history_viewmodel.dart';
import 'features/transcribe/repository/transcribe_repository.dart';
import 'features/transcribe/viewmodel/transcribe_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final authRepository = AuthRepository();
  final historyRepository = HistoryRepository();
  final transcribeRepository = TranscribeRepository(backendWsUrl: backendWsUrl);

  final authVM = AuthViewModel(authRepository);
  await authVM.restoreSession();
  final historyVM = HistoryViewModel(historyRepository, authVM);
  final transcribeVM = TranscribeViewModel(transcribeRepository, authVM, historyVM);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider.value(value: authVM),
        ChangeNotifierProvider.value(value: historyVM),
        ChangeNotifierProvider.value(value: transcribeVM),
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
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VoiceAI',
      themeMode: themeNotifier.mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeView(),
    );
  }
}
