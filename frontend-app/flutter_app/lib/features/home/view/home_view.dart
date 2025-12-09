import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../authentication/view/login_view.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../transcribe/view/transcribe_view.dart';
import 'history_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const LoginView();
        }
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: const [
              TranscribeView(),
              HistoryView(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.mic), label: 'Transcribe'),
              NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            ],
          ),
        );
      },
    );
  }
}
