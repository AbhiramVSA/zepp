import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/auth_session.dart';
import '../repository/auth_repository.dart';

enum AuthState { unauthenticated, authenticating, authenticated, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;

  AuthSession? _session;
  String? _error;
  AuthState _state = AuthState.unauthenticated;

  AuthState get state => _state;
  AuthSession? get session => _session;
  String? get error => _error;

  bool get isAuthenticated => _state == AuthState.authenticated && _session != null;

  Future<void> login(String email, String password) async {
    _state = AuthState.authenticating;
    _error = null;
    notifyListeners();

    try {
      _session = await _repository.login(email: email, password: password);
      _state = AuthState.authenticated;
      await _persistSession();
    } catch (e) {
      _session = null;
      _state = AuthState.error;
      _error = e is AuthException ? e.message : e.toString();
    }
    notifyListeners();
  }

  Future<void> signup(String email, String password) async {
    _state = AuthState.authenticating;
    _error = null;
    notifyListeners();

    try {
      _session = await _repository.signup(email: email, password: password);
      _state = AuthState.authenticated;
      await _persistSession();
    } catch (e) {
      _session = null;
      _state = AuthState.error;
      _error = e is AuthException ? e.message : e.toString();
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_session?.refreshToken == null) return;
    try {
      final refreshed = await _repository.refresh(_session!.refreshToken!);
      _session = refreshed;
      _state = AuthState.authenticated;
      await _persistSession();
      notifyListeners();
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  void logout() {
    _session = null;
    _error = null;
    _state = AuthState.unauthenticated;
    _clearPersisted();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('user_id');
    final email = prefs.getString('email');
    final refresh = prefs.getString('refresh_token');
    if (token != null && userId != null && email != null) {
      _session = AuthSession(
        accessToken: token,
        userId: userId,
        email: email,
        refreshToken: refresh,
      );
      _state = AuthState.authenticated;
      notifyListeners();
    }
  }

  Future<void> _persistSession() async {
    if (_session == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', _session!.accessToken);
    await prefs.setString('user_id', _session!.userId);
    await prefs.setString('email', _session!.email);
    if (_session!.refreshToken != null) {
      await prefs.setString('refresh_token', _session!.refreshToken!);
    } else {
      await prefs.remove('refresh_token');
    }
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.remove('email');
    await prefs.remove('refresh_token');
  }
}
