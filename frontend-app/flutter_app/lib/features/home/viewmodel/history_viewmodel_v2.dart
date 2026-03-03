import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/cache/cached_transcript.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../repository/history_repository_v2.dart';

/// State of the history view.
enum HistoryState {
  /// Initial state, no data loaded.
  idle,
  /// Loading data for the first time.
  loading,
  /// Data loaded successfully.
  loaded,
  /// Refreshing data in the background (pull-to-refresh).
  refreshing,
  /// Error loading data.
  error,
  /// User is not authenticated.
  unauthenticated,
}

/// ViewModel for transcript history with production-grade caching support.
///
/// This ViewModel implements:
/// - Cache-first loading with background refresh
/// - Optimistic UI updates for new transcripts
/// - Offline support with sync queue
/// - Diff-based UI updates (no unnecessary rebuilds)
/// - Proper cleanup on logout
///
/// The ViewModel coordinates between:
/// - HistoryRepository for data access
/// - AuthViewModel for user context
/// - UI layer for state updates
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
  
  /// Whether the currently displayed data came from cache.
  bool get isFromCache => _dataSource == CacheSource.memory || _dataSource == CacheSource.database;
  
  /// Whether a background refresh is in progress.
  bool get isBackgroundRefreshing => _isBackgroundRefreshing;
  
  /// Whether there are pending writes waiting to sync.
  bool get hasPendingWrites => _pendingSyncCount > 0;
  
  /// Whether there are any failed (unsynced) items.
  bool get hasFailedItems => _items.any((t) => !t.isSynced && !t.isOptimistic);

  /// Load transcript history.
  ///
  /// This method:
  /// 1. Returns cached data immediately if available
  /// 2. Shows loading indicator only if no cached data
  /// 3. Triggers background refresh automatically
  /// 4. Updates UI only if data actually changed
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

  /// Refresh from server (pull-to-refresh).
  /// Bypasses cache and fetches fresh data.
  Future<void> refresh() async {
    await load(refresh: true);
  }

  /// Load more items for pagination.
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

  /// Add a new transcript with optimistic update.
  ///
  /// The transcript appears immediately in the UI while being synced
  /// to the server in the background.
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

  /// Retry syncing a failed transcript.
  Future<void> retryFailedTranscript(String tempId) async {
    if (!_auth.isAuthenticated || _auth.session == null) return;

    await _repository.retryFailedTranscript(
      userId: _auth.session!.userId,
      tempId: tempId,
    );
  }

  /// Delete a failed transcript.
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

  /// Manually trigger sync of pending operations.
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

  /// Clear all cached data (call on logout).
  Future<void> clearCache() async {
    if (_auth.session != null) {
      await _repository.clearUserData(_auth.session!.userId);
    }
  }

  // ============================================================
  // PRIVATE METHODS
  // ============================================================

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
