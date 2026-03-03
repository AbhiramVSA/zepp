/// Cache-aware transcript model with metadata for sync state tracking.
/// 
/// This model extends the basic TranscriptItem with additional fields
/// required for the two-tier caching system:
/// - Staleness tracking via updatedAt and lastFetchedAt
/// - Optimistic write state via isOptimistic and isSynced
/// - LRU eviction tracking via lastAccessedAt
/// 
/// The model is designed to be serializable to both JSON (for API) and
/// the local SQLite database (via Drift).
class CachedTranscript {
  const CachedTranscript({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.lastFetchedAt,
    this.confidence,
    this.durationSeconds,
    this.audioUrl,
    this.lastAccessedAt,
    this.isOptimistic = false,
    this.isSynced = true,
    this.tempId,
  });

  /// Server-assigned UUID. For optimistic entries, this may be a temporary
  /// UUID until the server confirms the creation.
  final String id;

  /// User ID for multi-user cache isolation.
  final String userId;

  /// Transcript text content.
  final String text;

  /// Server-assigned creation timestamp.
  final DateTime createdAt;

  /// Server-assigned last update timestamp. Used for staleness detection.
  /// When comparing with server, if server's updatedAt > local updatedAt,
  /// the local entry is stale and should be refreshed.
  final DateTime updatedAt;

  /// When this item was last fetched from the server.
  /// Different from updatedAt: this tracks when WE fetched it, not when
  /// the server last modified it.
  final DateTime lastFetchedAt;

  /// When this item was last accessed (read) locally.
  /// Used for LRU eviction - least recently accessed items are evicted first,
  /// unless they are protected (unsynced/optimistic).
  final DateTime? lastAccessedAt;

  /// Optional transcription confidence score (0.0 - 1.0).
  final double? confidence;

  /// Duration of the original audio in seconds.
  final double? durationSeconds;

  /// URL to the original audio file, if stored.
  final String? audioUrl;

  /// True if this is an optimistic (locally-created) entry that hasn't
  /// been confirmed by the server yet. Optimistic entries are protected
  /// from LRU eviction.
  final bool isOptimistic;

  /// True if this entry is synchronized with the server.
  /// False for:
  /// - New optimistic entries pending creation
  /// - Entries that failed to sync
  /// Unsynced entries are protected from LRU eviction.
  final bool isSynced;

  /// Temporary local ID for optimistic entries.
  /// When the server confirms creation, the real ID replaces this.
  /// Allows UI to track the item through the optimistic -> synced transition.
  final String? tempId;

  /// Parse from server JSON response.
  /// Server responses don't include local-only fields like lastFetchedAt.
  factory CachedTranscript.fromServerJson(
    Map<String, dynamic> json, {
    required String userId,
    DateTime? fetchedAt,
  }) {
    final now = fetchedAt ?? DateTime.now();
    return CachedTranscript(
      id: json['id'] as String,
      userId: userId,
      text: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastFetchedAt: now,
      confidence: (json['confidence'] as num?)?.toDouble(),
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
      audioUrl: json['audio_url'] as String?,
      isOptimistic: false,
      isSynced: true,
    );
  }

  /// Create an optimistic entry for a new transcript before server confirmation.
  /// The tempId should be a locally-generated UUID.
  factory CachedTranscript.optimistic({
    required String tempId,
    required String userId,
    required String text,
    double? confidence,
    double? durationSeconds,
  }) {
    final now = DateTime.now();
    return CachedTranscript(
      id: tempId, // Use temp ID as primary key until server assigns real one
      userId: userId,
      text: text,
      createdAt: now,
      updatedAt: now,
      lastFetchedAt: now,
      lastAccessedAt: now,
      confidence: confidence,
      durationSeconds: durationSeconds,
      isOptimistic: true,
      isSynced: false,
      tempId: tempId,
    );
  }

  /// Convert to JSON for API requests.
  Map<String, dynamic> toServerJson() {
    return {
      'text': text,
      if (confidence != null) 'confidence': confidence,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (audioUrl != null) 'audio_url': audioUrl,
    };
  }

  /// Create a copy with updated fields.
  CachedTranscript copyWith({
    String? id,
    String? userId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastFetchedAt,
    DateTime? lastAccessedAt,
    double? confidence,
    double? durationSeconds,
    String? audioUrl,
    bool? isOptimistic,
    bool? isSynced,
    String? tempId,
  }) {
    return CachedTranscript(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      confidence: confidence ?? this.confidence,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioUrl: audioUrl ?? this.audioUrl,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      isSynced: isSynced ?? this.isSynced,
      tempId: tempId ?? this.tempId,
    );
  }

  /// Check if this item might be stale compared to a server timestamp.
  /// Returns true if the server version is newer.
  bool isStaleComparedTo(DateTime serverUpdatedAt) {
    return serverUpdatedAt.isAfter(updatedAt);
  }

  /// Check if this item is protected from eviction.
  /// Protected items: unsynced, optimistic, or recently accessed.
  bool get isEvictionProtected {
    // Never evict unsynced items - user would lose data
    if (!isSynced) return true;
    // Never evict optimistic items - they're pending server confirmation
    if (isOptimistic) return true;
    // Recently accessed items get some protection (last 5 minutes)
    if (lastAccessedAt != null) {
      final age = DateTime.now().difference(lastAccessedAt!);
      if (age.inMinutes < 5) return true;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedTranscript &&
        other.id == id &&
        other.userId == userId &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, userId, updatedAt);

  @override
  String toString() {
    return 'CachedTranscript(id: $id, text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, '
        'isOptimistic: $isOptimistic, isSynced: $isSynced)';
  }
}

/// Represents the result of a cache read operation.
class CacheReadResult {
  const CacheReadResult({
    required this.transcripts,
    required this.totalCount,
    required this.source,
    this.etag,
    this.lastModified,
    this.hasMore = false,
  });

  /// The transcripts retrieved from cache.
  final List<CachedTranscript> transcripts;

  /// Total count of transcripts for this user (for pagination).
  final int totalCount;

  /// Where the data came from.
  final CacheSource source;

  /// ETag for conditional fetching.
  final String? etag;

  /// Last modified timestamp for conditional fetching.
  final DateTime? lastModified;

  /// Whether there are more items beyond this page.
  final bool hasMore;

  /// Whether any items in the result might be stale.
  bool get mayBeStale => source == CacheSource.memory || source == CacheSource.database;
}

/// Indicates the source of cached data.
enum CacheSource {
  /// Data came from in-memory cache (fastest).
  memory,
  /// Data came from local SQLite database.
  database,
  /// Data came fresh from the server.
  server,
  /// Server returned 304 Not Modified (cache is fresh).
  notModified,
}
