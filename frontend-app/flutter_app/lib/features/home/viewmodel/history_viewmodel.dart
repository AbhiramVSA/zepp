import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/cache/cached_transcript.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../repository/history_repository.dart';

enum HistoryState { idle, loading, loaded, refreshing, error, unauthenticated }

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repository, this._auth) {
    _auth.addListener(_handleAuthChange);
    // Start background sync services
    _repository.startBackgroundServices();
    // Listen for cache changes
    if (_auth.isAuthenticated && _auth.session != null) {
      _setupCacheListener();
    }
  }

  final HistoryRepository _repository;
  final AuthViewModel _auth;

  // State
  List<CachedTranscript> _items = <CachedTranscript>[];
  HistoryState _state = HistoryState.idle;
  String? _error;
  CacheSource _dataSource = CacheSource.memory;
  int _totalCount = 0;
  int _pendingSyncCount = 0;
  bool _hasMore = false;
  bool _isBackgroundRefreshing = false;

  // Getters
  List<CachedTranscript> get items => _items;
  HistoryState get state => _state;
  String? get error => _error;
  int get totalCount => _totalCount;
  int get pendingSyncCount => _pendingSyncCount;
  bool get hasMore => _hasMore;
  
  bool get isFromCache => _dataSource == CacheSource.memory || _dataSource == CacheSource.database;
  bool get isBackgroundRefreshing => _isBackgroundRefreshing;
  bool get hasPendingWrites => _pendingSyncCount > 0;
  bool get hasFailedItems => _items.any((t) => !t.isSynced && !t.isOptimistic);

  Future<void> load({bool refresh = false}) async {
    if (!_auth.isAuthenticated || _auth.session == null) {
      _setUnauthenticated();
      return;
    }

    // Prevent concurrent loads
    if (_state == HistoryState.loading && !refresh) return;

    final session = _auth.session!;
    final userId = session.userId;

    // For refresh (pull-to-refresh), show refreshing state
    if (refresh) {
      if (_items.isNotEmpty) {
        _state = HistoryState.refreshing;
        notifyListeners();
      } else {
        _state = HistoryState.loading;
        notifyListeners();
      }
    } else if (_items.isEmpty) {
      _state = HistoryState.loading;
      notifyListeners();
    }

    _error = null;

    try {
      final result = await _repository.fetchHistory(
        userId: userId,
        token: session.accessToken,
        forceRefresh: refresh,
        triggerBackgroundRefresh: !refresh, // Don't double-refresh on pull-to-refresh
      );

      // Check if data actually changed before updating
      final itemsChanged = _itemsChanged(result.transcripts);
      
      if (itemsChanged || _state != HistoryState.loaded) {
        _items = result.transcripts;
        _totalCount = result.totalCount;
        _hasMore = result.hasMore;
        _dataSource = result.source;
        _pendingSyncCount = result.pendingSyncCount;
        _state = HistoryState.loaded;
        notifyListeners();

        _logDebug('Loaded ${result.transcripts.length} items (source: ${result.source}, changed: $itemsChanged)');
      } else {
        // Data unchanged, just update metadata
        _pendingSyncCount = result.pendingSyncCount;
        _state = HistoryState.loaded;
        
        // Don't notify if only transitioning from loading to loaded with same data
        if (_state == HistoryState.refreshing) {
          notifyListeners();
        }
      }

      // If we got cached data and refresh wasn't forced, data will be refreshed in background
      // When background refresh completes, the cache listener will update us
      if (result.isFromCache && !refresh) {
        _isBackgroundRefreshing = true;
        notifyListeners();
      }
    } catch (e) {
      _logDebug('Load failed: $e');
      
      if (_items.isNotEmpty) {
        // Keep showing cached data on error
        _state = HistoryState.loaded;
        _logDebug('Using cached data after error');
      } else {
        _state = HistoryState.error;
        _error = _formatError(e);
      }
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load(refresh: true);
  }

  Future<void> loadMore() async {
    if (!_auth.isAuthenticated || _auth.session == null) return;
    if (!_hasMore || _state == HistoryState.loading) return;

    final session = _auth.session!;
    
    try {
      final result = await _repository.fetchHistory(
        userId: session.userId,
        token: session.accessToken,
        offset: _items.length,
        forceRefresh: true, // Always fetch from server for pagination
        triggerBackgroundRefresh: false,
      );

      _items = [..._items, ...result.transcripts];
      _totalCount = result.totalCount;
      _hasMore = result.hasMore;
      _pendingSyncCount = result.pendingSyncCount;
      notifyListeners();
    } catch (e) {
      _logDebug('Load more failed: $e');
      // Don't update error state - we still have existing data
    }
  }

  Future<CachedTranscript> addTranscript({
    required String text,
    double? confidence,
    double? durationSeconds,
  }) async {
    if (!_auth.isAuthenticated || _auth.session == null) {
      throw StateError('User must be authenticated to create transcripts');
    }

    final session = _auth.session!;

    final transcript = await _repository.createTranscript(
      userId: session.userId,
      token: session.accessToken,
      text: text,
      confidence: confidence,
      durationSeconds: durationSeconds,
    );

    // Add to beginning of list (optimistic update)
    _items = [transcript, ..._items];
    _totalCount++;
    
    // Update pending count if not synced
    if (!transcript.isSynced) {
      _pendingSyncCount++;
    }
    
    notifyListeners();

    return transcript;
  }

  Future<void> retryFailedTranscript(String tempId) async {
    if (!_auth.isAuthenticated || _auth.session == null) return;

    await _repository.retryFailedTranscript(
      userId: _auth.session!.userId,
      tempId: tempId,
    );
  }

  Future<void> deleteFailedTranscript(String tempId) async {
    if (!_auth.isAuthenticated || _auth.session == null) return;

    await _repository.deleteFailedTranscript(
      userId: _auth.session!.userId,
      tempId: tempId,
    );

    // Remove from local list
    _items = _items.where((t) => t.id != tempId).toList();
    _totalCount = (_totalCount - 1).clamp(0, _totalCount);
    _pendingSyncCount = (_pendingSyncCount - 1).clamp(0, _pendingSyncCount);
    notifyListeners();
  }

  Future<void> syncPending() async {
    if (!_auth.isAuthenticated || _auth.session == null) return;

    // Check connectivity
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) {
      _logDebug('No connectivity, cannot sync');
      return;
    }

    final syncedCount = await _repository.syncPendingOperations();
    if (syncedCount > 0) {
      _logDebug('Synced $syncedCount pending operations');
      // Refresh to get updated data
      await load(refresh: true);
    }
  }

  Future<void> clearCache() async {
    if (_auth.session != null) {
      await _repository.clearUserData(_auth.session!.userId);
    }
  }

  void _setupCacheListener() {
    if (_auth.session == null) return;
    
    _repository.addCacheListener(_auth.session!.userId, _onCacheChanged);
  }

  void _removeCacheListener() {
    if (_auth.session == null) return;
    
    _repository.removeCacheListener(_auth.session!.userId, _onCacheChanged);
  }

  void _onCacheChanged() {
    // Cache was updated (e.g., by background refresh)
    // Reload data to reflect changes
    _isBackgroundRefreshing = false;
    
    if (_auth.isAuthenticated && _auth.session != null) {
      // Re-fetch from cache (should be instant since it's already in memory)
      _repository.fetchHistory(
        userId: _auth.session!.userId,
        token: _auth.session!.accessToken,
        forceRefresh: false,
        triggerBackgroundRefresh: false,
      ).then((result) {
        if (_itemsChanged(result.transcripts)) {
          _items = result.transcripts;
          _totalCount = result.totalCount;
          _hasMore = result.hasMore;
          _dataSource = result.source;
          _pendingSyncCount = result.pendingSyncCount;
          notifyListeners();
          _logDebug('Cache update: ${result.transcripts.length} items');
        }
      }).catchError((e) {
        _logDebug('Cache update failed: $e');
      });
    }
  }

  bool _itemsChanged(List<CachedTranscript> newItems) {
    if (newItems.length != _items.length) return true;
    if (newItems.isEmpty && _items.isEmpty) return false;
    if (newItems.isEmpty || _items.isEmpty) return true;

    // Compare first few items by ID and updatedAt
    final checkCount = newItems.length.clamp(0, 5);
    for (var i = 0; i < checkCount; i++) {
      if (newItems[i].id != _items[i].id) return true;
      if (newItems[i].updatedAt != _items[i].updatedAt) return true;
      if (newItems[i].isSynced != _items[i].isSynced) return true;
    }

    return false;
  }

  void _setUnauthenticated() {
    _items = <CachedTranscript>[];
    _state = HistoryState.unauthenticated;
    _error = null;
    _totalCount = 0;
    _pendingSyncCount = 0;
    _hasMore = false;
    notifyListeners();
  }

  void _handleAuthChange() {
    if (!_auth.isAuthenticated) {
      _removeCacheListener();
      clearCache();
      _setUnauthenticated();
    } else if (_auth.session != null) {
      _setupCacheListener();
      // Auto-load on fresh login
      load(refresh: true);
    }
  }

  String _formatError(dynamic error) {
    final message = error.toString();
    if (message.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    if (message.contains('401') || message.contains('Unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    return 'Failed to load transcripts. Please try again.';
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('HISTORY_VM: $message');
    }
  }

  @override
  void dispose() {
    _removeCacheListener();
    _auth.removeListener(_handleAuthChange);
    _repository.stopBackgroundServices();
    super.dispose();
  }
}
