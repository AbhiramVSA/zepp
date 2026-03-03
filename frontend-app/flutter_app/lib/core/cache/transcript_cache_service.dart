import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'cached_transcript.dart';
import 'package:drift/drift.dart';

/// Production-grade two-tier cache service for transcripts.
///
/// Architecture:
/// - Tier 1: In-memory LRU cache for instant reads
/// - Tier 2: SQLite database via Drift for persistence
///
/// Key features:
/// - Per-user cache isolation (multi-user safe)
/// - Per-item staleness tracking (no global TTL)
/// - Optimistic write support with rollback
/// - LRU eviction with protection for unsynced items
/// - Offline-first reads
///
/// Read strategy:
/// 1. Check memory cache (instant)
/// 2. If miss, check SQLite (fast)
/// 3. If data exists, return immediately
/// 4. Mark stale items for background refresh
/// 5. UI updates only if server data differs
///
/// Write strategy:
/// 1. Insert optimistically to cache
/// 2. Queue for server sync
/// 3. On success: update with server ID, mark synced
/// 4. On failure: mark failed, allow retry
class TranscriptCacheService {
  TranscriptCacheService({
    AppDatabase? database,
    int maxMemoryCacheSize = 100,
  })  : _database = database ?? AppDatabase(),
        _maxMemoryCacheSize = maxMemoryCacheSize;

  final AppDatabase _database;
  final int _maxMemoryCacheSize;

  /// In-memory LRU cache: userId -> LinkedHashMap<transcriptId, transcript>
  /// LinkedHashMap maintains insertion order for LRU implementation.
  final Map<String, LinkedHashMap<String, CachedTranscript>> _memoryCache = {};

  /// Per-user cache metadata (ETag, lastModified, totalCount)
  final Map<String, _UserCacheMetadata> _metadataCache = {};

  /// Listeners for cache changes (for reactive UI updates)
  final Map<String, Set<VoidCallback>> _listeners = {};

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get transcripts for a user using cache-first strategy.
  ///
  /// Read order:
  /// 1. Memory cache (instant, may be stale)
  /// 2. Database (fast, may be stale)
  /// 3. Returns whatever is available; caller should trigger background refresh
  ///
  /// Returns null if no cached data exists for this user.
  Future<CacheReadResult?> getTranscripts({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    // Tier 1: Check memory cache
    final memoryResult = _getFromMemory(userId, limit, offset);
    if (memoryResult != null) {
      _logDebug('Memory cache hit for user $userId: ${memoryResult.transcripts.length} items');
      return memoryResult;
    }

    // Tier 2: Check database
    final dbResult = await _getFromDatabase(userId, limit, offset);
    if (dbResult != null) {
      // Populate memory cache for future reads
      _populateMemoryCache(userId, dbResult.transcripts);
      _logDebug('Database cache hit for user $userId: ${dbResult.transcripts.length} items');
      return dbResult;
    }

    _logDebug('Cache miss for user $userId');
    return null;
  }

  /// Get a single transcript by ID.
  /// Updates lastAccessedAt for LRU tracking.
  Future<CachedTranscript?> getTranscript({
    required String userId,
    required String transcriptId,
  }) async {
    // Check memory first
    final userCache = _memoryCache[userId];
    if (userCache != null && userCache.containsKey(transcriptId)) {
      final transcript = userCache[transcriptId]!;
      // Move to end (most recently used) for LRU
      userCache.remove(transcriptId);
      userCache[transcriptId] = transcript.copyWith(lastAccessedAt: DateTime.now());
      return transcript;
    }

    // Check database
    final row = await (_database.select(_database.cachedTranscripts)
          ..where((t) => t.id.equals(transcriptId) & t.odooUserId.equals(userId)))
        .getSingleOrNull();

    if (row != null) {
      final transcript = _rowToTranscript(row);
      // Update lastAccessedAt in database
      await (_database.update(_database.cachedTranscripts)
            ..where((t) => t.id.equals(transcriptId) & t.odooUserId.equals(userId)))
          .write(CachedTranscriptsCompanion(lastAccessedAt: Value(DateTime.now())));
      // Add to memory cache
      _addToMemoryCache(userId, transcript);
      return transcript;
    }

    return null;
  }

  /// Get cache metadata for conditional fetching.
  Future<CacheMetadataInfo?> getCacheMetadata(String userId) async {
    // Check memory first
    if (_metadataCache.containsKey(userId)) {
      final meta = _metadataCache[userId]!;
      return CacheMetadataInfo(
        etag: meta.etag,
        lastModified: meta.lastModified,
        totalCount: meta.totalCount,
      );
    }

    // Check database
    final row = await (_database.select(_database.cacheMetadata)
          ..where((t) => t.odooUserId.equals(userId)))
        .getSingleOrNull();

    if (row != null) {
      final meta = _UserCacheMetadata(
        etag: row.etag,
        lastModified: row.lastModified,
        totalCount: row.totalCount ?? 0,
        lastFullFetchAt: row.lastFullFetchAt,
      );
      _metadataCache[userId] = meta;
      return CacheMetadataInfo(
        etag: meta.etag,
        lastModified: meta.lastModified,
        totalCount: meta.totalCount,
      );
    }

    return null;
  }

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Store transcripts from server response.
  /// This is the primary method for populating the cache after a server fetch.
  ///
  /// [transcripts] - Items from server
  /// [userId] - User these belong to
  /// [totalCount] - Total items available on server (for pagination)
  /// [etag] - Server ETag for conditional fetching
  /// [lastModified] - Server last-modified timestamp
  /// [isFullRefresh] - If true, this replaces all cached data for the user
  Future<void> storeServerResponse({
    required String userId,
    required List<CachedTranscript> transcripts,
    required int totalCount,
    String? etag,
    DateTime? lastModified,
    bool isFullRefresh = false,
  }) async {
    final now = DateTime.now();

    // Begin database transaction for atomicity
    await _database.transaction(() async {
      if (isFullRefresh) {
        // Delete all synced items for this user (keep optimistic/unsynced)
        await (_database.delete(_database.cachedTranscripts)
              ..where((t) => t.odooUserId.equals(userId) & t.isSynced.equals(true)))
            .go();
      }

      // Batch insert/update transcripts
      for (final transcript in transcripts) {
        await _database.into(_database.cachedTranscripts).insertOnConflictUpdate(
              CachedTranscriptsCompanion.insert(
                id: transcript.id,
                odooUserId: userId,
                transcriptText: transcript.text,
                confidence: Value(transcript.confidence),
                durationSeconds: Value(transcript.durationSeconds),
                audioUrl: Value(transcript.audioUrl),
                createdAt: transcript.createdAt,
                updatedAt: transcript.updatedAt,
                lastFetchedAt: now,
                lastAccessedAt: Value(now),
                isOptimistic: Value(false),
                isSynced: Value(true),
              ),
            );
      }

      // Update metadata
      await _database.into(_database.cacheMetadata).insertOnConflictUpdate(
            CacheMetadataCompanion.insert(
              odooUserId: userId,
              etag: Value(etag),
              lastModified: Value(lastModified),
              totalCount: Value(totalCount),
              lastFullFetchAt: Value(now),
            ),
          );
    });

    // Update memory cache
    _metadataCache[userId] = _UserCacheMetadata(
      etag: etag,
      lastModified: lastModified,
      totalCount: totalCount,
      lastFullFetchAt: now,
    );

    if (isFullRefresh) {
      _memoryCache[userId] = LinkedHashMap();
    }
    _populateMemoryCache(userId, transcripts);

    // Enforce LRU limit
    await _enforceMemoryLimit(userId);

    // Notify listeners of cache update
    _notifyListeners(userId);

    _logDebug('Stored ${transcripts.length} transcripts for user $userId (total: $totalCount)');
  }

  /// Insert an optimistic transcript before server confirmation.
  /// Returns the transcript with its temporary ID.
  Future<CachedTranscript> insertOptimistic({
    required String userId,
    required String tempId,
    required String text,
    double? confidence,
    double? durationSeconds,
  }) async {
    final transcript = CachedTranscript.optimistic(
      tempId: tempId,
      userId: userId,
      text: text,
      confidence: confidence,
      durationSeconds: durationSeconds,
    );

    // Insert to database
    await _database.into(_database.cachedTranscripts).insert(
          CachedTranscriptsCompanion.insert(
            id: tempId,
            odooUserId: userId,
            transcriptText: text,
            confidence: Value(confidence),
            durationSeconds: Value(durationSeconds),
            createdAt: transcript.createdAt,
            updatedAt: transcript.updatedAt,
            lastFetchedAt: transcript.lastFetchedAt,
            lastAccessedAt: Value(DateTime.now()),
            isOptimistic: const Value(true),
            isSynced: const Value(false),
            tempId: Value(tempId),
          ),
        );

    // Add to memory cache at front (newest first)
    _addToMemoryCacheFront(userId, transcript);

    // Update local total count
    final meta = _metadataCache[userId];
    if (meta != null) {
      _metadataCache[userId] = _UserCacheMetadata(
        etag: null, // Invalidate ETag since we have local changes
        lastModified: meta.lastModified,
        totalCount: meta.totalCount + 1,
        lastFullFetchAt: meta.lastFullFetchAt,
      );
    }

    _notifyListeners(userId);

    _logDebug('Inserted optimistic transcript: $tempId for user $userId');
    return transcript;
  }

  /// Confirm an optimistic transcript with server response.
  /// Replaces the temp ID with the real server ID and marks as synced.
  Future<void> confirmOptimistic({
    required String userId,
    required String tempId,
    required CachedTranscript confirmedTranscript,
  }) async {
    await _database.transaction(() async {
      // Delete the optimistic entry
      await (_database.delete(_database.cachedTranscripts)
            ..where((t) => t.id.equals(tempId) & t.odooUserId.equals(userId)))
          .go();

      // Insert the confirmed entry
      await _database.into(_database.cachedTranscripts).insert(
            CachedTranscriptsCompanion.insert(
              id: confirmedTranscript.id,
              odooUserId: userId,
              transcriptText: confirmedTranscript.text,
              confidence: Value(confirmedTranscript.confidence),
              durationSeconds: Value(confirmedTranscript.durationSeconds),
              audioUrl: Value(confirmedTranscript.audioUrl),
              createdAt: confirmedTranscript.createdAt,
              updatedAt: confirmedTranscript.updatedAt,
              lastFetchedAt: DateTime.now(),
              lastAccessedAt: Value(DateTime.now()),
              isOptimistic: const Value(false),
              isSynced: const Value(true),
            ),
          );
    });

    // Update memory cache
    final userCache = _memoryCache[userId];
    if (userCache != null) {
      userCache.remove(tempId);
      _addToMemoryCacheFront(userId, confirmedTranscript);
    }

    _notifyListeners(userId);

    _logDebug('Confirmed optimistic transcript: $tempId -> ${confirmedTranscript.id}');
  }

  /// Mark an optimistic write as failed.
  /// The item remains in cache but is marked for retry.
  Future<void> markOptimisticFailed({
    required String userId,
    required String tempId,
  }) async {
    await (_database.update(_database.cachedTranscripts)
          ..where((t) => t.id.equals(tempId) & t.odooUserId.equals(userId)))
        .write(const CachedTranscriptsCompanion(isSynced: Value(false)));

    // Update memory cache
    final userCache = _memoryCache[userId];
    if (userCache != null && userCache.containsKey(tempId)) {
      final transcript = userCache[tempId]!;
      userCache[tempId] = transcript.copyWith(isSynced: false);
    }

    _notifyListeners(userId);

    _logDebug('Marked optimistic transcript as failed: $tempId');
  }

  /// Rollback (delete) a failed optimistic write.
  Future<void> rollbackOptimistic({
    required String userId,
    required String tempId,
  }) async {
    await (_database.delete(_database.cachedTranscripts)
          ..where((t) => t.id.equals(tempId) & t.odooUserId.equals(userId)))
        .go();

    // Remove from memory cache
    _memoryCache[userId]?.remove(tempId);

    // Update total count
    final meta = _metadataCache[userId];
    if (meta != null && meta.totalCount > 0) {
      _metadataCache[userId] = _UserCacheMetadata(
        etag: meta.etag,
        lastModified: meta.lastModified,
        totalCount: meta.totalCount - 1,
        lastFullFetchAt: meta.lastFullFetchAt,
      );
    }

    _notifyListeners(userId);

    _logDebug('Rolled back optimistic transcript: $tempId');
  }

  /// Get all unsynced (pending) transcripts for a user.
  Future<List<CachedTranscript>> getUnsyncedTranscripts(String userId) async {
    final rows = await (_database.select(_database.cachedTranscripts)
          ..where((t) => t.odooUserId.equals(userId) & t.isSynced.equals(false)))
        .get();
    return rows.map(_rowToTranscript).toList();
  }

  // ============================================================
  // CACHE MANAGEMENT
  // ============================================================

  /// Clear all cached data for a user (e.g., on logout).
  /// This is atomic: either all data is cleared or none.
  Future<void> clearUserCache(String userId) async {
    await _database.transaction(() async {
      // Delete transcripts
      await (_database.delete(_database.cachedTranscripts)
            ..where((t) => t.odooUserId.equals(userId)))
          .go();

      // Delete sync queue
      await (_database.delete(_database.syncQueue)
            ..where((t) => t.odooUserId.equals(userId)))
          .go();

      // Delete metadata
      await (_database.delete(_database.cacheMetadata)
            ..where((t) => t.odooUserId.equals(userId)))
          .go();
    });

    // Clear memory cache
    _memoryCache.remove(userId);
    _metadataCache.remove(userId);

    _notifyListeners(userId);

    _logDebug('Cleared all cache for user $userId');
  }

  /// Clear all cached data (e.g., on app reset).
  Future<void> clearAllCaches() async {
    await _database.transaction(() async {
      await _database.delete(_database.cachedTranscripts).go();
      await _database.delete(_database.syncQueue).go();
      await _database.delete(_database.cacheMetadata).go();
    });

    _memoryCache.clear();
    _metadataCache.clear();

    // Notify all listeners
    for (final userId in _listeners.keys.toList()) {
      _notifyListeners(userId);
    }

    _logDebug('Cleared all caches');
  }

  /// Invalidate cache metadata to force refresh on next fetch.
  /// Keeps the cached data but marks it as stale.
  Future<void> invalidateCache(String userId) async {
    await (_database.update(_database.cacheMetadata)
          ..where((t) => t.odooUserId.equals(userId)))
        .write(const CacheMetadataCompanion(etag: Value(null)));

    if (_metadataCache.containsKey(userId)) {
      final meta = _metadataCache[userId]!;
      _metadataCache[userId] = _UserCacheMetadata(
        etag: null,
        lastModified: meta.lastModified,
        totalCount: meta.totalCount,
        lastFullFetchAt: meta.lastFullFetchAt,
      );
    }

    _logDebug('Invalidated cache for user $userId');
  }

  // ============================================================
  // LISTENERS
  // ============================================================

  /// Add a listener for cache changes for a specific user.
  void addListener(String userId, VoidCallback listener) {
    _listeners.putIfAbsent(userId, () => {});
    _listeners[userId]!.add(listener);
  }

  /// Remove a listener.
  void removeListener(String userId, VoidCallback listener) {
    _listeners[userId]?.remove(listener);
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  CacheReadResult? _getFromMemory(String userId, int limit, int offset) {
    final userCache = _memoryCache[userId];
    final meta = _metadataCache[userId];
    
    // If no cache and no metadata, this is a true cache miss (never fetched)
    if (userCache == null || userCache.isEmpty) {
      // But if we have metadata, we've fetched before - return empty result
      if (meta != null) {
        return CacheReadResult(
          transcripts: [],
          totalCount: meta.totalCount,
          source: CacheSource.memory,
          etag: meta.etag,
          lastModified: meta.lastModified,
          hasMore: false,
        );
      }
      return null;
    }

    final allItems = userCache.values.toList().reversed.toList(); // Newest first
    
    // If offset is past all items but we have metadata, return empty page (not miss)
    if (offset >= allItems.length) {
      if (meta != null) {
        return CacheReadResult(
          transcripts: [],
          totalCount: meta.totalCount,
          source: CacheSource.memory,
          etag: meta.etag,
          lastModified: meta.lastModified,
          hasMore: false,
        );
      }
      return null;
    }

    final endIndex = (offset + limit).clamp(0, allItems.length);
    final items = allItems.sublist(offset, endIndex);

    return CacheReadResult(
      transcripts: items,
      totalCount: meta?.totalCount ?? allItems.length,
      source: CacheSource.memory,
      etag: meta?.etag,
      lastModified: meta?.lastModified,
      hasMore: endIndex < allItems.length,
    );
  }

  Future<CacheReadResult?> _getFromDatabase(String userId, int limit, int offset) async {
    final rows = await (_database.select(_database.cachedTranscripts)
          ..where((t) => t.odooUserId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit, offset: offset))
        .get();

    // Get metadata first to determine if we've ever fetched for this user
    final metaRow = await (_database.select(_database.cacheMetadata)
          ..where((t) => t.odooUserId.equals(userId)))
        .getSingleOrNull();

    // If no rows and offset=0, check if we have metadata
    // If metadata exists, we've fetched before - return empty result (not miss)
    // If no metadata, this is a true cache miss (never fetched)
    if (rows.isEmpty && offset == 0) {
      if (metaRow != null) {
        return CacheReadResult(
          transcripts: [],
          totalCount: metaRow.totalCount ?? 0,
          source: CacheSource.database,
          etag: metaRow.etag,
          lastModified: metaRow.lastModified,
          hasMore: false,
        );
      }
      return null;
    }

    final transcripts = rows.map(_rowToTranscript).toList();
    final totalCount = metaRow?.totalCount ?? transcripts.length;

    return CacheReadResult(
      transcripts: transcripts,
      totalCount: totalCount,
      source: CacheSource.database,
      etag: metaRow?.etag,
      lastModified: metaRow?.lastModified,
      hasMore: offset + transcripts.length < totalCount,
    );
  }

  void _populateMemoryCache(String userId, List<CachedTranscript> transcripts) {
    _memoryCache.putIfAbsent(userId, () => LinkedHashMap());
    for (final transcript in transcripts) {
      _memoryCache[userId]![transcript.id] = transcript;
    }
  }

  void _addToMemoryCache(String userId, CachedTranscript transcript) {
    _memoryCache.putIfAbsent(userId, () => LinkedHashMap());
    _memoryCache[userId]![transcript.id] = transcript;
    _enforceMemoryLimitSync(userId);
  }

  void _addToMemoryCacheFront(String userId, CachedTranscript transcript) {
    _memoryCache.putIfAbsent(userId, () => LinkedHashMap());
    final userCache = _memoryCache[userId]!;
    // To add at front, we need to rebuild the map
    final newCache = LinkedHashMap<String, CachedTranscript>();
    newCache[transcript.id] = transcript;
    newCache.addAll(userCache);
    _memoryCache[userId] = newCache;
    _enforceMemoryLimitSync(userId);
  }

  Future<void> _enforceMemoryLimit(String userId) async {
    final userCache = _memoryCache[userId];
    if (userCache == null || userCache.length <= _maxMemoryCacheSize) return;

    // Find items to evict (oldest accessed, not protected)
    final evictionCandidates = userCache.entries
        .where((e) => !e.value.isEvictionProtected)
        .toList();

    // Sort by lastAccessedAt (oldest first)
    evictionCandidates.sort((a, b) {
      final aTime = a.value.lastAccessedAt ?? a.value.lastFetchedAt;
      final bTime = b.value.lastAccessedAt ?? b.value.lastFetchedAt;
      return aTime.compareTo(bTime);
    });

    // Evict until under limit
    final toEvict = evictionCandidates
        .take(userCache.length - _maxMemoryCacheSize)
        .map((e) => e.key)
        .toList();

    for (final id in toEvict) {
      userCache.remove(id);
    }

    _logDebug('Evicted ${toEvict.length} items from memory cache for user $userId');
  }

  void _enforceMemoryLimitSync(String userId) {
    final userCache = _memoryCache[userId];
    if (userCache == null || userCache.length <= _maxMemoryCacheSize) return;

    final evictionCandidates = userCache.entries
        .where((e) => !e.value.isEvictionProtected)
        .toList();

    evictionCandidates.sort((a, b) {
      final aTime = a.value.lastAccessedAt ?? a.value.lastFetchedAt;
      final bTime = b.value.lastAccessedAt ?? b.value.lastFetchedAt;
      return aTime.compareTo(bTime);
    });

    final toEvict = evictionCandidates
        .take(userCache.length - _maxMemoryCacheSize)
        .map((e) => e.key)
        .toList();

    for (final id in toEvict) {
      userCache.remove(id);
    }
  }

  CachedTranscript _rowToTranscript(CachedTranscriptEntry row) {
    return CachedTranscript(
      id: row.id,
      userId: row.odooUserId,
      text: row.transcriptText,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastFetchedAt: row.lastFetchedAt,
      lastAccessedAt: row.lastAccessedAt,
      confidence: row.confidence,
      durationSeconds: row.durationSeconds,
      audioUrl: row.audioUrl,
      isOptimistic: row.isOptimistic,
      isSynced: row.isSynced,
      tempId: row.tempId,
    );
  }

  void _notifyListeners(String userId) {
    final listeners = _listeners[userId];
    if (listeners != null) {
      for (final listener in listeners.toList()) {
        listener();
      }
    }
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('CACHE: $message');
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    await _database.close();
  }
}

/// Internal cache metadata per user.
class _UserCacheMetadata {
  const _UserCacheMetadata({
    this.etag,
    this.lastModified,
    required this.totalCount,
    this.lastFullFetchAt,
  });

  final String? etag;
  final DateTime? lastModified;
  final int totalCount;
  final DateTime? lastFullFetchAt;
}

/// Public cache metadata for conditional fetching.
class CacheMetadataInfo {
  const CacheMetadataInfo({
    this.etag,
    this.lastModified,
    required this.totalCount,
  });

  final String? etag;
  final DateTime? lastModified;
  final int totalCount;
}
