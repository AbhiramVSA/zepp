// GENERATED CODE WILL BE ADDED BY drift_dev
// Run: dart run build_runner build
//
// This file defines the Drift database schema for local transcript caching.
// The database provides:
// - Persistent storage of transcripts per user
// - Offline queue for pending write operations
// - Cache metadata tracking for staleness detection

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Cached transcript table.
/// 
/// Stores transcript data locally with additional metadata for cache management.
/// All entries are namespaced by userId to support multi-user scenarios.
@DataClassName('CachedTranscriptEntry')
class CachedTranscripts extends Table {
  // Primary key: server-assigned transcript ID (UUID string)
  TextColumn get id => text().named('id')();
  
  // User isolation: each user's transcripts are stored separately
  TextColumn get odooUserId => text().named('user_id')();
  
  // Transcript content
  TextColumn get transcriptText => text().named('text')();
  
  // Optional metadata from server
  RealColumn get confidence => real().nullable()();
  RealColumn get durationSeconds => real().nullable()();
  TextColumn get audioUrl => text().nullable()();
  
  // Server timestamps for staleness detection
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  // Local cache metadata
  // When this item was last fetched from server
  DateTimeColumn get lastFetchedAt => dateTime()();
  // When this item was last accessed (read) locally - for LRU eviction
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  
  // Optimistic write tracking
  // True if this is a locally-created item pending server confirmation
  BoolColumn get isOptimistic => boolean().withDefault(const Constant(false))();
  // True if the item has been confirmed by the server
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  // Temporary local ID for optimistic items (before server assigns real ID)
  TextColumn get tempId => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id, odooUserId};
}

/// Offline write queue for pending operations.
/// 
/// When the device is offline, write operations are queued here.
/// On reconnection, queued operations are replayed in order.
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  // Auto-incrementing ID ensures FIFO ordering
  IntColumn get id => integer().autoIncrement()();
  
  // User who initiated the operation
  TextColumn get odooUserId => text().named('user_id')();
  
  // Operation type: 'create', 'update', 'delete'
  TextColumn get operation => text()();
  
  // JSON-encoded payload for the operation
  TextColumn get payload => text()();
  
  // Temporary ID for tracking optimistic entries
  TextColumn get tempId => text().nullable()();
  
  // Retry tracking
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  
  // Error tracking for failed attempts
  TextColumn get lastError => text().nullable()();
}

/// Cache metadata per user.
/// 
/// Tracks global cache state for each user including:
/// - ETag for conditional fetching
/// - Last modified timestamp
/// - Total count for pagination
@DataClassName('CacheMetadataEntry')
class CacheMetadata extends Table {
  TextColumn get odooUserId => text().named('user_id')();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get lastModified => dateTime().nullable()();
  IntColumn get totalCount => integer().nullable()();
  DateTimeColumn get lastFullFetchAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {odooUserId};
}

@DriftDatabase(tables: [CachedTranscripts, SyncQueue, CacheMetadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // Increment schema version when making breaking changes to tables
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema migrations here
        // Example:
        // if (from < 2) {
        //   await m.addColumn(cachedTranscripts, cachedTranscripts.newColumn);
        // }
      },
      beforeOpen: (details) async {
        // Enable foreign keys for referential integrity
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'voiceai_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
