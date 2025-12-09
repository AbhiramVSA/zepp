import 'package:flutter/foundation.dart';

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
    } catch (e) {
      _session = null;
      _state = AuthState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  void logout() {
    _session = null;
    _error = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
