import 'package:flutter/foundation.dart';

import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../model/transcript_item.dart';
import '../repository/history_repository.dart';

enum HistoryState { idle, loading, loaded, refreshing, error, unauthenticated }

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repository, this._auth) {
    _auth.addListener(_handleAuthChange);
  }

  final HistoryRepository _repository;
  final AuthViewModel _auth;

  List<TranscriptItem> _items = <TranscriptItem>[];
  HistoryState _state = HistoryState.idle;
  String? _error;
  bool _isFromCache = false;

  List<TranscriptItem> get items => _items;
  HistoryState get state => _state;
  String? get error => _error;
  bool get isFromCache => _isFromCache;

  /// Load history with cache-first strategy.
  /// Shows cached data immediately, then refreshes in background if needed.
  Future<void> load({bool refresh = false}) async {
    if (!_auth.isAuthenticated) {
      _items = <TranscriptItem>[];
      _state = HistoryState.unauthenticated;
      _isFromCache = false;
      notifyListeners();
      return;
    }

    if (!refresh && _state == HistoryState.loading) return;

    // If refreshing and we have data, show refreshing state
    if (refresh && _items.isNotEmpty) {
      _state = HistoryState.refreshing;
    } else {
      _state = HistoryState.loading;
    }
    _error = null;
    notifyListeners();

    try {
      final session = _auth.session!;
      final history = await _repository.fetchHistory(
        token: session.accessToken,
        forceRefresh: refresh,
      );
      _items = history.items;
      _isFromCache = history.fromCache;
      _state = HistoryState.loaded;

      // If we got cached data, fetch fresh data in background
      if (history.fromCache && !refresh) {
        _refreshInBackground(session.accessToken);
      }
    } catch (e) {
      // If we have cached items, keep showing them on error
      if (_items.isNotEmpty) {
        _state = HistoryState.loaded;
        if (kDebugMode) {
          // ignore: avoid_print
          print('HISTORY: Network error, using cached data: $e');
        }
      } else {
        _state = HistoryState.error;
        _error = e.toString();
      }
    }
    notifyListeners();
  }

  /// Force refresh from server (pull-to-refresh).
  Future<void> refresh() async {
    await load(refresh: true);
  }

  /// Add a newly created transcript to the list and cache.
  Future<void> addTranscript(TranscriptItem transcript) async {
    // Add to beginning of list
    _items = [transcript, ..._items];
    notifyListeners();

    // Update cache
    await _repository.cacheNewTranscript(transcript);
  }

  /// Clear cache (call on logout).
  Future<void> clearCache() async {
    await _repository.clearCache();
  }

  void _refreshInBackground(String token) async {
    try {
      if (kDebugMode) {
        // ignore: avoid_print
        print('HISTORY: Background refresh started');
      }
      final history = await _repository.refreshHistory(token: token);
      
      // Only update if items changed
      if (_itemsChanged(history.items)) {
        _items = history.items;
        _isFromCache = false;
        notifyListeners();
        if (kDebugMode) {
          // ignore: avoid_print
          print('HISTORY: Background refresh updated ${history.items.length} items');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('HISTORY: Background refresh failed: $e');
      }
    }
  }

  bool _itemsChanged(List<TranscriptItem> newItems) {
    if (newItems.length != _items.length) return true;
    if (newItems.isEmpty) return false;
    // Quick check: compare first item ID
    return newItems.first.id != _items.first.id;
  }

  void _handleAuthChange() {
    if (!_auth.isAuthenticated) {
      _items = <TranscriptItem>[];
      _state = HistoryState.unauthenticated;
      _isFromCache = false;
      clearCache();
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
