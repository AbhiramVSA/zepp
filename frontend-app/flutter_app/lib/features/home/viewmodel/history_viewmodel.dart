import 'package:flutter/foundation.dart';

import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../model/transcript_item.dart';
import '../repository/history_repository.dart';

enum HistoryState { idle, loading, loaded, error, unauthenticated }

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repository, this._auth) {
    _auth.addListener(_handleAuthChange);
  }

  final HistoryRepository _repository;
  final AuthViewModel _auth;

  List<TranscriptItem> _items = <TranscriptItem>[];
  HistoryState _state = HistoryState.idle;
  String? _error;

  List<TranscriptItem> get items => _items;
  HistoryState get state => _state;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (!_auth.isAuthenticated) {
      _items = <TranscriptItem>[];
      _state = HistoryState.unauthenticated;
      notifyListeners();
      return;
    }

    if (!refresh && _state == HistoryState.loading) return;

    _state = HistoryState.loading;
    _error = null;
    notifyListeners();

    try {
      final session = _auth.session!;
      final history = await _repository.fetchHistory(token: session.accessToken);
      _items = history.items;
      _state = HistoryState.loaded;
    } catch (e) {
      _state = HistoryState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  void _handleAuthChange() {
    if (!_auth.isAuthenticated) {
      _items = <TranscriptItem>[];
      _state = HistoryState.unauthenticated;
      notifyListeners();
    } else {
      // auto-load on fresh login
      load(refresh: true);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChange);
    super.dispose();
  }
}
