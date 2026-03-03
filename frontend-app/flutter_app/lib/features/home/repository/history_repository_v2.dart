import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/app_config.dart';
import '../../../core/cache/cached_transcript.dart';
import '../../../core/cache/sync_queue_service.dart';
import '../../../core/cache/transcript_cache_service.dart';
import '../../../core/database/app_database.dart';

/// Result of a history fetch operation.
class HistoryResult {
  const HistoryResult({
    required this.transcripts,
    required this.totalCount,
    required this.source,
    this.hasMore = false,
    this.pendingSyncCount = 0,
  });

  final List<CachedTranscript> transcripts;
  final int totalCount;
  final CacheSource source;
  final bool hasMore;
  final int pendingSyncCount;

  /// Whether this data came from cache (memory or database).
  bool get isFromCache => source == CacheSource.memory || source == CacheSource.database;

  /// Whether the server returned 304 Not Modified.
  bool get wasNotModified => source == CacheSource.notModified;
}

/// Repository for managing transcript history with two-tier caching.
///
/// This repository implements a production-grade caching strategy:
///
/// Read Strategy (Strict):
/// 1. Check memory cache
/// 2. If miss, check local SQLite database
/// 3. If data exists, return immediately
/// 4. Mark stale per-item (NOT global TTL)
/// 5. Trigger background refresh if stale
/// 6. Update UI only if server data differs (diff-based)
///
/// Write Strategy:
/// 1. Insert optimistically to cache
/// 2. Mark isOptimistic = true
/// 3. On server confirmation: replace temp ID, mark isSynced = true
/// 4. On failure: rollback or mark failed
///
/// Offline Support:
/// - Reads always work from cache
/// - Writes are queued for later sync
/// - Conflicts resolved using server timestamp (server wins)
class HistoryRepository {
  HistoryRepository({
    AppDatabase? database,
    TranscriptCacheService? cacheService,
    http.Client? httpClient,
  })  : _database = database ?? AppDatabase(),
        _httpClient = httpClient ?? http.Client() {
    _cacheService = cacheService ?? TranscriptCacheService(database: _database);
    _syncQueueService = SyncQueueService(
      database: _database,
      cacheService: _cacheService,
      syncCallback: _executeSyncOperation,
    );
  }

  final AppDatabase _database;
  final http.Client _httpClient;
  late final TranscriptCacheService _cacheService;
  late final SyncQueueService _syncQueueService;
  
  final _uuid = const Uuid();

  /// Start background services (call on app init).
  void startBackgroundServices() {
    _syncQueueService.startListening();
  }

  /// Stop background services (call on app dispose).
  void stopBackgroundServices() {
    _syncQueueService.stopListening();
  }

  /// Fetch transcript history for a user.
  ///
  /// Uses cache-first strategy:
  /// 1. Returns cached data immediately if available
  /// 2. Optionally triggers background refresh
  ///
  /// [userId] - The user's ID for cache isolation
  /// [token] - JWT token for server requests
  /// [forceRefresh] - If true, bypasses cache (pull-to-refresh)
  /// [triggerBackgroundRefresh] - If true, fetches fresh data after returning cache
  Future<HistoryResult> fetchHistory({
    required String userId,
    required String token,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
    bool triggerBackgroundRefresh = true,
  }) async {
    // For pull-to-refresh or explicit bypass, go directly to server
    if (forceRefresh) {
      return _fetchFromServer(
        userId: userId,
        token: token,
        limit: limit,
        offset: offset,
        useConditionalFetch: false, // Full refresh
      );
    }

    // Try cache first
    final cacheResult = await _cacheService.getTranscripts(
      userId: userId,
      limit: limit,
      offset: offset,
    );

    // cacheResult != null means we have valid cached data (even if empty)
    // null means we've never fetched for this user (true cache miss)
    if (cacheResult != null) {
      final pendingCount = await _syncQueueService.getPendingCount(userId);

      _logDebug('Returning ${cacheResult.transcripts.length} cached items (source: ${cacheResult.source})');

      // Schedule background refresh if caller wants it and we have items
      // Don't background refresh for empty cache - avoid unnecessary requests
      if (triggerBackgroundRefresh && offset == 0 && cacheResult.transcripts.isNotEmpty) {
        _scheduleBackgroundRefresh(userId: userId, token: token, limit: limit);
      }

      return HistoryResult(
        transcripts: cacheResult.transcripts,
        totalCount: cacheResult.totalCount,
        source: cacheResult.source,
        hasMore: cacheResult.hasMore,
        pendingSyncCount: pendingCount,
      );
    }

    // No cached data (never fetched), must fetch from server
    _logDebug('Cache miss - fetching from server');
    return _fetchFromServer(
      userId: userId,
      token: token,
      limit: limit,
      offset: offset,
      useConditionalFetch: false,
    );
  }

  /// Refresh history from server using conditional fetch.
  ///
  /// Uses If-Modified-Since and If-None-Match headers to avoid
  /// downloading unchanged data. Returns the current cache state
  /// if server returns 304 Not Modified.
  Future<HistoryResult> refreshHistory({
    required String userId,
    required String token,
    int limit = 50,
    int offset = 0,
  }) async {
    return _fetchFromServer(
      userId: userId,
      token: token,
      limit: limit,
      offset: offset,
      useConditionalFetch: true,
    );
  }

  /// Create a new transcript with optimistic update.
  ///
  /// The transcript is immediately added to the cache with isOptimistic = true.
  /// The UI can render it immediately. On server confirmation, the temp ID
  /// is replaced with the real ID and isSynced becomes true.
  ///
  /// If offline, the operation is queued and synced when connectivity returns.
  ///
  /// Returns the optimistic transcript immediately.
  Future<CachedTranscript> createTranscript({
    required String userId,
    required String token,
    required String text,
    double? confidence,
    double? durationSeconds,
  }) async {
    final tempId = _uuid.v4();

    // Insert optimistically to cache
    final optimisticTranscript = await _cacheService.insertOptimistic(
      userId: userId,
      tempId: tempId,
      text: text,
      confidence: confidence,
      durationSeconds: durationSeconds,
    );

    // Check connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResults.any((r) => r != ConnectivityResult.none);

    if (hasConnection) {
      // Try to sync immediately
      try {
        final confirmed = await _createOnServer(
          token: token,
          text: text,
          confidence: confidence,
          durationSeconds: durationSeconds,
        );

        if (confirmed != null) {
          // Confirm the optimistic entry
          await _cacheService.confirmOptimistic(
            userId: userId,
            tempId: tempId,
            confirmedTranscript: CachedTranscript.fromServerJson(confirmed, userId: userId),
          );

          return CachedTranscript.fromServerJson(confirmed, userId: userId);
        }
      } catch (e) {
        _logDebug('Immediate sync failed, queueing for later: $e');
        // Fall through to queue
      }
    }

    // Queue for later sync (offline or failed)
    await _syncQueueService.queueCreate(
      userId: userId,
      tempId: tempId,
      text: text,
      confidence: confidence,
      durationSeconds: durationSeconds,
    );

    return optimisticTranscript;
  }

  /// Retry a failed transcript creation.
  Future<void> retryFailedTranscript({
    required String userId,
    required String tempId,
  }) async {
    final transcript = await _cacheService.getTranscript(
      userId: userId,
      transcriptId: tempId,
    );

    if (transcript != null && !transcript.isSynced) {
      await _syncQueueService.queueCreate(
        userId: userId,
        tempId: tempId,
        text: transcript.text,
        confidence: transcript.confidence,
        durationSeconds: transcript.durationSeconds,
      );
    }
  }

  /// Delete a failed optimistic transcript.
  Future<void> deleteFailedTranscript({
    required String userId,
    required String tempId,
  }) async {
    await _cacheService.rollbackOptimistic(
      userId: userId,
      tempId: tempId,
    );
  }

  /// Clear all cached data for a user (call on logout).
  Future<void> clearUserData(String userId) async {
    await _syncQueueService.clearPendingOperations(userId);
    await _cacheService.clearUserCache(userId);
  }

  /// Get count of pending sync operations.
  Future<int> getPendingSyncCount(String userId) async {
    return _syncQueueService.getPendingCount(userId);
  }

  /// Manually trigger sync of pending operations.
  Future<int> syncPendingOperations() async {
    return _syncQueueService.syncPendingOperations();
  }

  /// Add a listener for cache changes.
  void addCacheListener(String userId, VoidCallback listener) {
    _cacheService.addListener(userId, listener);
  }

  /// Remove a cache listener.
  void removeCacheListener(String userId, VoidCallback listener) {
    _cacheService.removeListener(userId, listener);
  }

  // ============================================================
  // PRIVATE METHODS
  // ============================================================

  Future<HistoryResult> _fetchFromServer({
    required String userId,
    required String token,
    required int limit,
    required int offset,
    required bool useConditionalFetch,
  }) async {
    final uri = Uri.parse('$backendBaseUrl/transcripts/history?limit=$limit&offset=$offset');
    _logDebug('Fetching from server: $uri (conditional: $useConditionalFetch)');

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    // Add conditional headers if we have cached metadata
    if (useConditionalFetch) {
      final metadata = await _cacheService.getCacheMetadata(userId);
      if (metadata != null) {
        if (metadata.etag != null) {
          headers['If-None-Match'] = metadata.etag!;
        }
        if (metadata.lastModified != null) {
          headers['If-Modified-Since'] = _formatHttpDate(metadata.lastModified!);
        }
      }
    }

    try {
      final response = await _httpClient.get(uri, headers: headers);
      _logDebug('Server response: ${response.statusCode}');

      // Handle 304 Not Modified
      if (response.statusCode == 304) {
        _logDebug('Server returned 304 Not Modified, using cache');
        final cacheResult = await _cacheService.getTranscripts(
          userId: userId,
          limit: limit,
          offset: offset,
        );

        final pendingCount = await _syncQueueService.getPendingCount(userId);

        return HistoryResult(
          transcripts: cacheResult?.transcripts ?? [],
          totalCount: cacheResult?.totalCount ?? 0,
          source: CacheSource.notModified,
          hasMore: cacheResult?.hasMore ?? false,
          pendingSyncCount: pendingCount,
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load history (${response.statusCode}): ${response.body}');
      }

      // Parse response
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final rawItems = jsonBody['items'] as List<dynamic>? ?? <dynamic>[];
      final totalCount = (jsonBody['total'] as num?)?.toInt() ?? rawItems.length;
      final etag = jsonBody['etag'] as String? ?? response.headers['etag'];
      final lastUpdatedStr = jsonBody['last_updated'] as String?;
      final lastUpdated = lastUpdatedStr != null ? DateTime.parse(lastUpdatedStr) : null;

      final fetchedAt = DateTime.now();
      final transcripts = rawItems
          .map((e) => CachedTranscript.fromServerJson(
                e as Map<String, dynamic>,
                userId: userId,
                fetchedAt: fetchedAt,
              ))
          .toList();

      // Store in cache
      await _cacheService.storeServerResponse(
        userId: userId,
        transcripts: transcripts,
        totalCount: totalCount,
        etag: etag,
        lastModified: lastUpdated,
        isFullRefresh: offset == 0,
      );

      final pendingCount = await _syncQueueService.getPendingCount(userId);

      _logDebug('Fetched ${transcripts.length} transcripts from server (total: $totalCount)');

      return HistoryResult(
        transcripts: transcripts,
        totalCount: totalCount,
        source: CacheSource.server,
        hasMore: offset + transcripts.length < totalCount,
        pendingSyncCount: pendingCount,
      );
    } catch (e) {
      _logDebug('Server fetch failed: $e');

      // On error, try to return cached data
      final cacheResult = await _cacheService.getTranscripts(
        userId: userId,
        limit: limit,
        offset: offset,
      );

      if (cacheResult != null && cacheResult.transcripts.isNotEmpty) {
        final pendingCount = await _syncQueueService.getPendingCount(userId);
        _logDebug('Returning cached data after server error');
        return HistoryResult(
          transcripts: cacheResult.transcripts,
          totalCount: cacheResult.totalCount,
          source: cacheResult.source,
          hasMore: cacheResult.hasMore,
          pendingSyncCount: pendingCount,
        );
      }

      // No cache, rethrow
      rethrow;
    }
  }

  void _scheduleBackgroundRefresh({
    required String userId,
    required String token,
    required int limit,
  }) {
    // Use Future.delayed to avoid blocking the current operation
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await refreshHistory(userId: userId, token: token, limit: limit);
      } catch (e) {
        _logDebug('Background refresh failed: $e');
        // Silently fail - we already have cached data
      }
    });
  }

  Future<Map<String, dynamic>?> _createOnServer({
    required String token,
    required String text,
    double? confidence,
    double? durationSeconds,
  }) async {
    final uri = Uri.parse('$backendBaseUrl/transcripts/');
    
    final body = jsonEncode({
      'text': text,
      if (confidence != null) 'confidence': confidence,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to create transcript (${response.statusCode}): ${response.body}');
  }

  /// Callback for SyncQueueService to execute sync operations.
  Future<CachedTranscript?> _executeSyncOperation(SyncOperation operation) async {
    // Note: We need a token to make API calls. The SyncQueueService doesn't
    // have access to the auth token, so we need to handle this differently.
    // For now, we'll throw and let the sync be retried when the user is active.
    throw UnimplementedError(
      'Sync operations should be triggered by the ViewModel which has auth context',
    );
  }

  /// Execute a sync operation with the provided token.
  /// Called by the ViewModel when connectivity is restored.
  Future<CachedTranscript?> executeSyncWithToken({
    required SyncOperation operation,
    required String token,
    required String userId,
  }) async {
    if (operation.isCreate) {
      final result = await _createOnServer(
        token: token,
        text: operation.payload['text'] as String,
        confidence: (operation.payload['confidence'] as num?)?.toDouble(),
        durationSeconds: (operation.payload['duration_seconds'] as num?)?.toDouble(),
      );

      if (result != null) {
        return CachedTranscript.fromServerJson(result, userId: userId);
      }
    }

    return null;
  }

  String _formatHttpDate(DateTime date) {
    // HTTP date format: Wed, 21 Oct 2015 07:28:00 GMT
    final utc = date.toUtc();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekdays[utc.weekday - 1]}, '
        '${utc.day.toString().padLeft(2, '0')} '
        '${months[utc.month - 1]} '
        '${utc.year} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')} GMT';
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('HISTORY_REPO: $message');
    }
  }

  /// Close resources.
  Future<void> dispose() async {
    stopBackgroundServices();
    _httpClient.close();
    await _cacheService.close();
  }
}
