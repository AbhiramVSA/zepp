import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'cached_transcript.dart';
import 'transcript_cache_service.dart';

/// Service for managing offline write operations and syncing when connectivity restores.
///
/// This service:
/// - Queues write operations when offline
/// - Replays queued operations when connectivity returns
/// - Handles conflicts using server timestamp (server wins)
/// - Provides retry logic with exponential backoff
/// - Cleans up completed operations
///
/// All queue operations are persisted to SQLite, so they survive app restarts.
class SyncQueueService {
  SyncQueueService({
    required AppDatabase database,
    required TranscriptCacheService cacheService,
    required Future<CachedTranscript?> Function(SyncOperation) syncCallback,
  })  : _database = database,
        _cacheService = cacheService,
        _syncCallback = syncCallback;

  final AppDatabase _database;
  final TranscriptCacheService _cacheService;
  final Future<CachedTranscript?> Function(SyncOperation) _syncCallback;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _retryTimer;

  /// Maximum retry attempts before marking an operation as failed
  static const int maxRetries = 5;

  /// Base delay for exponential backoff (milliseconds)
  static const int baseRetryDelayMs = 1000;

  /// Start listening for connectivity changes.
  /// Call this when the service is initialized.
  void startListening() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        _logDebug('Connectivity restored, triggering sync');
        syncPendingOperations();
      }
    });
  }

  /// Stop listening for connectivity changes.
  /// Call this when the service is disposed.
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Queue a create operation for later sync.
  /// Returns immediately after queuing; the actual sync happens asynchronously.
  Future<void> queueCreate({
    required String userId,
    required String tempId,
    required String text,
    double? confidence,
    double? durationSeconds,
  }) async {
    final payload = jsonEncode({
      'text': text,
      if (confidence != null) 'confidence': confidence,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });

    await _database.into(_database.syncQueue).insert(
          SyncQueueCompanion.insert(
            odooUserId: userId,
            operation: 'create',
            payload: payload,
            tempId: Value(tempId),
            createdAt: DateTime.now(),
          ),
        );

    _logDebug('Queued create operation for temp ID: $tempId');

    // Try to sync immediately if online
    _scheduleSyncAttempt();
  }

  /// Get all pending operations for a user.
  Future<List<SyncOperation>> getPendingOperations(String userId) async {
    final rows = await (_database.select(_database.syncQueue)
          ..where((t) => t.odooUserId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();

    return rows.map((row) => SyncOperation(
          id: row.id,
          userId: row.odooUserId,
          operation: row.operation,
          payload: jsonDecode(row.payload) as Map<String, dynamic>,
          tempId: row.tempId,
          retryCount: row.retryCount,
          createdAt: row.createdAt,
          lastAttemptAt: row.lastAttemptAt,
          lastError: row.lastError,
        )).toList();
  }

  /// Get count of pending operations.
  Future<int> getPendingCount(String userId) async {
    final count = await (_database.selectOnly(_database.syncQueue)
          ..where(_database.syncQueue.odooUserId.equals(userId))
          ..addColumns([_database.syncQueue.id.count()]))
        .map((row) => row.read(_database.syncQueue.id.count()))
        .getSingle();
    return count ?? 0;
  }

  /// Check if there are any pending operations.
  Future<bool> hasPendingOperations(String userId) async {
    final count = await getPendingCount(userId);
    return count > 0;
  }

  /// Sync all pending operations.
  /// Returns the number of successfully synced operations.
  Future<int> syncPendingOperations() async {
    if (_isSyncing) {
      _logDebug('Sync already in progress, skipping');
      return 0;
    }

    // Check connectivity first
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResults.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) {
      _logDebug('No connectivity, skipping sync');
      return 0;
    }

    _isSyncing = true;
    int syncedCount = 0;

    try {
      // Get all pending operations ordered by creation time
      final rows = await (_database.select(_database.syncQueue)
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

      if (rows.isEmpty) {
        _logDebug('No pending operations to sync');
        return 0;
      }

      _logDebug('Syncing ${rows.length} pending operations');

      for (final row in rows) {
        final operation = SyncOperation(
          id: row.id,
          userId: row.odooUserId,
          operation: row.operation,
          payload: jsonDecode(row.payload) as Map<String, dynamic>,
          tempId: row.tempId,
          retryCount: row.retryCount,
          createdAt: row.createdAt,
          lastAttemptAt: row.lastAttemptAt,
          lastError: row.lastError,
        );

        try {
          final result = await _syncCallback(operation);
          
          if (result != null && operation.tempId != null) {
            // Success: confirm the optimistic entry and remove from queue
            await _cacheService.confirmOptimistic(
              userId: operation.userId,
              tempId: operation.tempId!,
              confirmedTranscript: result,
            );
          }

          // Remove from queue
          await (_database.delete(_database.syncQueue)
                ..where((t) => t.id.equals(operation.id)))
              .go();

          syncedCount++;
          _logDebug('Synced operation ${operation.id} (${operation.operation})');
        } catch (e) {
          // Handle failure
          final newRetryCount = row.retryCount + 1;

          if (newRetryCount >= maxRetries) {
            // Max retries exceeded: mark the optimistic entry as failed
            _logDebug('Operation ${operation.id} exceeded max retries, marking as failed');
            
            if (operation.tempId != null) {
              await _cacheService.markOptimisticFailed(
                userId: operation.userId,
                tempId: operation.tempId!,
              );
            }

            // Remove from queue
            await (_database.delete(_database.syncQueue)
                  ..where((t) => t.id.equals(operation.id)))
                .go();
          } else {
            // Update retry count and error
            await (_database.update(_database.syncQueue)
                  ..where((t) => t.id.equals(operation.id)))
                .write(SyncQueueCompanion(
                  retryCount: Value(newRetryCount),
                  lastAttemptAt: Value(DateTime.now()),
                  lastError: Value(e.toString()),
                ));

            _logDebug('Operation ${operation.id} failed (retry $newRetryCount/$maxRetries): $e');

            // Schedule retry with exponential backoff
            _scheduleRetry(newRetryCount);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  /// Clear all pending operations for a user (e.g., on logout).
  Future<void> clearPendingOperations(String userId) async {
    await (_database.delete(_database.syncQueue)
          ..where((t) => t.odooUserId.equals(userId)))
        .go();
    _logDebug('Cleared pending operations for user $userId');
  }

  /// Clear all pending operations (e.g., on app reset).
  Future<void> clearAllPendingOperations() async {
    await _database.delete(_database.syncQueue).go();
    _logDebug('Cleared all pending operations');
  }

  void _scheduleSyncAttempt() {
    // Cancel existing timer
    _retryTimer?.cancel();
    // Schedule immediate sync attempt
    _retryTimer = Timer(const Duration(milliseconds: 100), () {
      syncPendingOperations();
    });
  }

  void _scheduleRetry(int retryCount) {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delayMs = baseRetryDelayMs * (1 << (retryCount - 1));
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(milliseconds: delayMs), () {
      syncPendingOperations();
    });
    _logDebug('Scheduled retry in ${delayMs}ms');
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('SYNC_QUEUE: $message');
    }
  }
}

/// Represents a queued sync operation.
class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.userId,
    required this.operation,
    required this.payload,
    this.tempId,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.lastError,
  });

  final int id;
  final String userId;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic> payload;
  final String? tempId;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? lastError;

  bool get isCreate => operation == 'create';
  bool get isUpdate => operation == 'update';
  bool get isDelete => operation == 'delete';

  @override
  String toString() {
    return 'SyncOperation(id: $id, operation: $operation, tempId: $tempId, retries: $retryCount)';
  }
}
