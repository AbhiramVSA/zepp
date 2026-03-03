// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedTranscriptsTable extends CachedTranscripts
    with TableInfo<$CachedTranscriptsTable, CachedTranscriptEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTranscriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _odooUserIdMeta = const VerificationMeta(
    'odooUserId',
  );
  @override
  late final GeneratedColumn<String> odooUserId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transcriptTextMeta = const VerificationMeta(
    'transcriptText',
  );
  @override
  late final GeneratedColumn<String> transcriptText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isOptimisticMeta = const VerificationMeta(
    'isOptimistic',
  );
  @override
  late final GeneratedColumn<bool> isOptimistic = GeneratedColumn<bool>(
    'is_optimistic',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_optimistic" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _tempIdMeta = const VerificationMeta('tempId');
  @override
  late final GeneratedColumn<String> tempId = GeneratedColumn<String>(
    'temp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    odooUserId,
    transcriptText,
    confidence,
    durationSeconds,
    audioUrl,
    createdAt,
    updatedAt,
    lastFetchedAt,
    lastAccessedAt,
    isOptimistic,
    isSynced,
    tempId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_transcripts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTranscriptEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _odooUserIdMeta,
        odooUserId.isAcceptableOrUnknown(data['user_id']!, _odooUserIdMeta),
      );
    } else if (isInserting) {
      context.missing(_odooUserIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _transcriptTextMeta,
        transcriptText.isAcceptableOrUnknown(
          data['text']!,
          _transcriptTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transcriptTextMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastFetchedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_optimistic')) {
      context.handle(
        _isOptimisticMeta,
        isOptimistic.isAcceptableOrUnknown(
          data['is_optimistic']!,
          _isOptimisticMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('temp_id')) {
      context.handle(
        _tempIdMeta,
        tempId.isAcceptableOrUnknown(data['temp_id']!, _tempIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, odooUserId};
  @override
  CachedTranscriptEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTranscriptEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      odooUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      transcriptText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration_seconds'],
      ),
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      ),
      isOptimistic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_optimistic'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      tempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_id'],
      ),
    );
  }

  @override
  $CachedTranscriptsTable createAlias(String alias) {
    return $CachedTranscriptsTable(attachedDatabase, alias);
  }
}

class CachedTranscriptEntry extends DataClass
    implements Insertable<CachedTranscriptEntry> {
  final String id;
  final String odooUserId;
  final String transcriptText;
  final double? confidence;
  final double? durationSeconds;
  final String? audioUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastFetchedAt;
  final DateTime? lastAccessedAt;
  final bool isOptimistic;
  final bool isSynced;
  final String? tempId;
  const CachedTranscriptEntry({
    required this.id,
    required this.odooUserId,
    required this.transcriptText,
    this.confidence,
    this.durationSeconds,
    this.audioUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.lastFetchedAt,
    this.lastAccessedAt,
    required this.isOptimistic,
    required this.isSynced,
    this.tempId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(odooUserId);
    map['text'] = Variable<String>(transcriptText);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<double>(durationSeconds);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    map['is_optimistic'] = Variable<bool>(isOptimistic);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || tempId != null) {
      map['temp_id'] = Variable<String>(tempId);
    }
    return map;
  }

  CachedTranscriptsCompanion toCompanion(bool nullToAbsent) {
    return CachedTranscriptsCompanion(
      id: Value(id),
      odooUserId: Value(odooUserId),
      transcriptText: Value(transcriptText),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastFetchedAt: Value(lastFetchedAt),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
      isOptimistic: Value(isOptimistic),
      isSynced: Value(isSynced),
      tempId: tempId == null && nullToAbsent
          ? const Value.absent()
          : Value(tempId),
    );
  }

  factory CachedTranscriptEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTranscriptEntry(
      id: serializer.fromJson<String>(json['id']),
      odooUserId: serializer.fromJson<String>(json['odooUserId']),
      transcriptText: serializer.fromJson<String>(json['transcriptText']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      durationSeconds: serializer.fromJson<double?>(json['durationSeconds']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastFetchedAt: serializer.fromJson<DateTime>(json['lastFetchedAt']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
      isOptimistic: serializer.fromJson<bool>(json['isOptimistic']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      tempId: serializer.fromJson<String?>(json['tempId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'odooUserId': serializer.toJson<String>(odooUserId),
      'transcriptText': serializer.toJson<String>(transcriptText),
      'confidence': serializer.toJson<double?>(confidence),
      'durationSeconds': serializer.toJson<double?>(durationSeconds),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastFetchedAt': serializer.toJson<DateTime>(lastFetchedAt),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
      'isOptimistic': serializer.toJson<bool>(isOptimistic),
      'isSynced': serializer.toJson<bool>(isSynced),
      'tempId': serializer.toJson<String?>(tempId),
    };
  }

  CachedTranscriptEntry copyWith({
    String? id,
    String? odooUserId,
    String? transcriptText,
    Value<double?> confidence = const Value.absent(),
    Value<double?> durationSeconds = const Value.absent(),
    Value<String?> audioUrl = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastFetchedAt,
    Value<DateTime?> lastAccessedAt = const Value.absent(),
    bool? isOptimistic,
    bool? isSynced,
    Value<String?> tempId = const Value.absent(),
  }) => CachedTranscriptEntry(
    id: id ?? this.id,
    odooUserId: odooUserId ?? this.odooUserId,
    transcriptText: transcriptText ?? this.transcriptText,
    confidence: confidence.present ? confidence.value : this.confidence,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    lastAccessedAt: lastAccessedAt.present
        ? lastAccessedAt.value
        : this.lastAccessedAt,
    isOptimistic: isOptimistic ?? this.isOptimistic,
    isSynced: isSynced ?? this.isSynced,
    tempId: tempId.present ? tempId.value : this.tempId,
  );
  CachedTranscriptEntry copyWithCompanion(CachedTranscriptsCompanion data) {
    return CachedTranscriptEntry(
      id: data.id.present ? data.id.value : this.id,
      odooUserId: data.odooUserId.present
          ? data.odooUserId.value
          : this.odooUserId,
      transcriptText: data.transcriptText.present
          ? data.transcriptText.value
          : this.transcriptText,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      isOptimistic: data.isOptimistic.present
          ? data.isOptimistic.value
          : this.isOptimistic,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      tempId: data.tempId.present ? data.tempId.value : this.tempId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTranscriptEntry(')
          ..write('id: $id, ')
          ..write('odooUserId: $odooUserId, ')
          ..write('transcriptText: $transcriptText, ')
          ..write('confidence: $confidence, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('isOptimistic: $isOptimistic, ')
          ..write('isSynced: $isSynced, ')
          ..write('tempId: $tempId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    odooUserId,
    transcriptText,
    confidence,
    durationSeconds,
    audioUrl,
    createdAt,
    updatedAt,
    lastFetchedAt,
    lastAccessedAt,
    isOptimistic,
    isSynced,
    tempId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTranscriptEntry &&
          other.id == this.id &&
          other.odooUserId == this.odooUserId &&
          other.transcriptText == this.transcriptText &&
          other.confidence == this.confidence &&
          other.durationSeconds == this.durationSeconds &&
          other.audioUrl == this.audioUrl &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastFetchedAt == this.lastFetchedAt &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.isOptimistic == this.isOptimistic &&
          other.isSynced == this.isSynced &&
          other.tempId == this.tempId);
}

class CachedTranscriptsCompanion
    extends UpdateCompanion<CachedTranscriptEntry> {
  final Value<String> id;
  final Value<String> odooUserId;
  final Value<String> transcriptText;
  final Value<double?> confidence;
  final Value<double?> durationSeconds;
  final Value<String?> audioUrl;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> lastFetchedAt;
  final Value<DateTime?> lastAccessedAt;
  final Value<bool> isOptimistic;
  final Value<bool> isSynced;
  final Value<String?> tempId;
  final Value<int> rowid;
  const CachedTranscriptsCompanion({
    this.id = const Value.absent(),
    this.odooUserId = const Value.absent(),
    this.transcriptText = const Value.absent(),
    this.confidence = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.isOptimistic = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.tempId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedTranscriptsCompanion.insert({
    required String id,
    required String odooUserId,
    required String transcriptText,
    this.confidence = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.audioUrl = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime lastFetchedAt,
    this.lastAccessedAt = const Value.absent(),
    this.isOptimistic = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.tempId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       odooUserId = Value(odooUserId),
       transcriptText = Value(transcriptText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       lastFetchedAt = Value(lastFetchedAt);
  static Insertable<CachedTranscriptEntry> custom({
    Expression<String>? id,
    Expression<String>? odooUserId,
    Expression<String>? transcriptText,
    Expression<double>? confidence,
    Expression<double>? durationSeconds,
    Expression<String>? audioUrl,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastFetchedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<bool>? isOptimistic,
    Expression<bool>? isSynced,
    Expression<String>? tempId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (odooUserId != null) 'user_id': odooUserId,
      if (transcriptText != null) 'text': transcriptText,
      if (confidence != null) 'confidence': confidence,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (isOptimistic != null) 'is_optimistic': isOptimistic,
      if (isSynced != null) 'is_synced': isSynced,
      if (tempId != null) 'temp_id': tempId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedTranscriptsCompanion copyWith({
    Value<String>? id,
    Value<String>? odooUserId,
    Value<String>? transcriptText,
    Value<double?>? confidence,
    Value<double?>? durationSeconds,
    Value<String?>? audioUrl,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? lastFetchedAt,
    Value<DateTime?>? lastAccessedAt,
    Value<bool>? isOptimistic,
    Value<bool>? isSynced,
    Value<String?>? tempId,
    Value<int>? rowid,
  }) {
    return CachedTranscriptsCompanion(
      id: id ?? this.id,
      odooUserId: odooUserId ?? this.odooUserId,
      transcriptText: transcriptText ?? this.transcriptText,
      confidence: confidence ?? this.confidence,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      isSynced: isSynced ?? this.isSynced,
      tempId: tempId ?? this.tempId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (odooUserId.present) {
      map['user_id'] = Variable<String>(odooUserId.value);
    }
    if (transcriptText.present) {
      map['text'] = Variable<String>(transcriptText.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<double>(durationSeconds.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (isOptimistic.present) {
      map['is_optimistic'] = Variable<bool>(isOptimistic.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (tempId.present) {
      map['temp_id'] = Variable<String>(tempId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTranscriptsCompanion(')
          ..write('id: $id, ')
          ..write('odooUserId: $odooUserId, ')
          ..write('transcriptText: $transcriptText, ')
          ..write('confidence: $confidence, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('isOptimistic: $isOptimistic, ')
          ..write('isSynced: $isSynced, ')
          ..write('tempId: $tempId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _odooUserIdMeta = const VerificationMeta(
    'odooUserId',
  );
  @override
  late final GeneratedColumn<String> odooUserId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempIdMeta = const VerificationMeta('tempId');
  @override
  late final GeneratedColumn<String> tempId = GeneratedColumn<String>(
    'temp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    odooUserId,
    operation,
    payload,
    tempId,
    retryCount,
    createdAt,
    lastAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _odooUserIdMeta,
        odooUserId.isAcceptableOrUnknown(data['user_id']!, _odooUserIdMeta),
      );
    } else if (isInserting) {
      context.missing(_odooUserIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('temp_id')) {
      context.handle(
        _tempIdMeta,
        tempId.isAcceptableOrUnknown(data['temp_id']!, _tempIdMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      odooUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      tempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_id'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int id;
  final String odooUserId;
  final String operation;
  final String payload;
  final String? tempId;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? lastError;
  const SyncQueueEntry({
    required this.id,
    required this.odooUserId,
    required this.operation,
    required this.payload,
    this.tempId,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(odooUserId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || tempId != null) {
      map['temp_id'] = Variable<String>(tempId);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      odooUserId: Value(odooUserId),
      operation: Value(operation),
      payload: Value(payload),
      tempId: tempId == null && nullToAbsent
          ? const Value.absent()
          : Value(tempId),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      odooUserId: serializer.fromJson<String>(json['odooUserId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      tempId: serializer.fromJson<String?>(json['tempId']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'odooUserId': serializer.toJson<String>(odooUserId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'tempId': serializer.toJson<String?>(tempId),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueEntry copyWith({
    int? id,
    String? odooUserId,
    String? operation,
    String? payload,
    Value<String?> tempId = const Value.absent(),
    int? retryCount,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueEntry(
    id: id ?? this.id,
    odooUserId: odooUserId ?? this.odooUserId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    tempId: tempId.present ? tempId.value : this.tempId,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      odooUserId: data.odooUserId.present
          ? data.odooUserId.value
          : this.odooUserId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      tempId: data.tempId.present ? data.tempId.value : this.tempId,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('odooUserId: $odooUserId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('tempId: $tempId, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    odooUserId,
    operation,
    payload,
    tempId,
    retryCount,
    createdAt,
    lastAttemptAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.odooUserId == this.odooUserId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.tempId == this.tempId &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> odooUserId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<String?> tempId;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> lastError;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.odooUserId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.tempId = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String odooUserId,
    required String operation,
    required String payload,
    this.tempId = const Value.absent(),
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : odooUserId = Value(odooUserId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? odooUserId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<String>? tempId,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (odooUserId != null) 'user_id': odooUserId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (tempId != null) 'temp_id': tempId,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? odooUserId,
    Value<String>? operation,
    Value<String>? payload,
    Value<String?>? tempId,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? lastError,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      odooUserId: odooUserId ?? this.odooUserId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      tempId: tempId ?? this.tempId,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (odooUserId.present) {
      map['user_id'] = Variable<String>(odooUserId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (tempId.present) {
      map['temp_id'] = Variable<String>(tempId.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('odooUserId: $odooUserId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('tempId: $tempId, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $CacheMetadataTable extends CacheMetadata
    with TableInfo<$CacheMetadataTable, CacheMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _odooUserIdMeta = const VerificationMeta(
    'odooUserId',
  );
  @override
  late final GeneratedColumn<String> odooUserId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCountMeta = const VerificationMeta(
    'totalCount',
  );
  @override
  late final GeneratedColumn<int> totalCount = GeneratedColumn<int>(
    'total_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFullFetchAtMeta = const VerificationMeta(
    'lastFullFetchAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFullFetchAt =
      GeneratedColumn<DateTime>(
        'last_full_fetch_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    odooUserId,
    etag,
    lastModified,
    totalCount,
    lastFullFetchAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheMetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _odooUserIdMeta,
        odooUserId.isAcceptableOrUnknown(data['user_id']!, _odooUserIdMeta),
      );
    } else if (isInserting) {
      context.missing(_odooUserIdMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('total_count')) {
      context.handle(
        _totalCountMeta,
        totalCount.isAcceptableOrUnknown(data['total_count']!, _totalCountMeta),
      );
    }
    if (data.containsKey('last_full_fetch_at')) {
      context.handle(
        _lastFullFetchAtMeta,
        lastFullFetchAt.isAcceptableOrUnknown(
          data['last_full_fetch_at']!,
          _lastFullFetchAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {odooUserId};
  @override
  CacheMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheMetadataEntry(
      odooUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      ),
      totalCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_count'],
      ),
      lastFullFetchAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_full_fetch_at'],
      ),
    );
  }

  @override
  $CacheMetadataTable createAlias(String alias) {
    return $CacheMetadataTable(attachedDatabase, alias);
  }
}

class CacheMetadataEntry extends DataClass
    implements Insertable<CacheMetadataEntry> {
  final String odooUserId;
  final String? etag;
  final DateTime? lastModified;
  final int? totalCount;
  final DateTime? lastFullFetchAt;
  const CacheMetadataEntry({
    required this.odooUserId,
    this.etag,
    this.lastModified,
    this.totalCount,
    this.lastFullFetchAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(odooUserId);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<DateTime>(lastModified);
    }
    if (!nullToAbsent || totalCount != null) {
      map['total_count'] = Variable<int>(totalCount);
    }
    if (!nullToAbsent || lastFullFetchAt != null) {
      map['last_full_fetch_at'] = Variable<DateTime>(lastFullFetchAt);
    }
    return map;
  }

  CacheMetadataCompanion toCompanion(bool nullToAbsent) {
    return CacheMetadataCompanion(
      odooUserId: Value(odooUserId),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      totalCount: totalCount == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCount),
      lastFullFetchAt: lastFullFetchAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFullFetchAt),
    );
  }

  factory CacheMetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheMetadataEntry(
      odooUserId: serializer.fromJson<String>(json['odooUserId']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastModified: serializer.fromJson<DateTime?>(json['lastModified']),
      totalCount: serializer.fromJson<int?>(json['totalCount']),
      lastFullFetchAt: serializer.fromJson<DateTime?>(json['lastFullFetchAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'odooUserId': serializer.toJson<String>(odooUserId),
      'etag': serializer.toJson<String?>(etag),
      'lastModified': serializer.toJson<DateTime?>(lastModified),
      'totalCount': serializer.toJson<int?>(totalCount),
      'lastFullFetchAt': serializer.toJson<DateTime?>(lastFullFetchAt),
    };
  }

  CacheMetadataEntry copyWith({
    String? odooUserId,
    Value<String?> etag = const Value.absent(),
    Value<DateTime?> lastModified = const Value.absent(),
    Value<int?> totalCount = const Value.absent(),
    Value<DateTime?> lastFullFetchAt = const Value.absent(),
  }) => CacheMetadataEntry(
    odooUserId: odooUserId ?? this.odooUserId,
    etag: etag.present ? etag.value : this.etag,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
    totalCount: totalCount.present ? totalCount.value : this.totalCount,
    lastFullFetchAt: lastFullFetchAt.present
        ? lastFullFetchAt.value
        : this.lastFullFetchAt,
  );
  CacheMetadataEntry copyWithCompanion(CacheMetadataCompanion data) {
    return CacheMetadataEntry(
      odooUserId: data.odooUserId.present
          ? data.odooUserId.value
          : this.odooUserId,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      totalCount: data.totalCount.present
          ? data.totalCount.value
          : this.totalCount,
      lastFullFetchAt: data.lastFullFetchAt.present
          ? data.lastFullFetchAt.value
          : this.lastFullFetchAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataEntry(')
          ..write('odooUserId: $odooUserId, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('totalCount: $totalCount, ')
          ..write('lastFullFetchAt: $lastFullFetchAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(odooUserId, etag, lastModified, totalCount, lastFullFetchAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheMetadataEntry &&
          other.odooUserId == this.odooUserId &&
          other.etag == this.etag &&
          other.lastModified == this.lastModified &&
          other.totalCount == this.totalCount &&
          other.lastFullFetchAt == this.lastFullFetchAt);
}

class CacheMetadataCompanion extends UpdateCompanion<CacheMetadataEntry> {
  final Value<String> odooUserId;
  final Value<String?> etag;
  final Value<DateTime?> lastModified;
  final Value<int?> totalCount;
  final Value<DateTime?> lastFullFetchAt;
  final Value<int> rowid;
  const CacheMetadataCompanion({
    this.odooUserId = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.lastFullFetchAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheMetadataCompanion.insert({
    required String odooUserId,
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.lastFullFetchAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : odooUserId = Value(odooUserId);
  static Insertable<CacheMetadataEntry> custom({
    Expression<String>? odooUserId,
    Expression<String>? etag,
    Expression<DateTime>? lastModified,
    Expression<int>? totalCount,
    Expression<DateTime>? lastFullFetchAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (odooUserId != null) 'user_id': odooUserId,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (totalCount != null) 'total_count': totalCount,
      if (lastFullFetchAt != null) 'last_full_fetch_at': lastFullFetchAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheMetadataCompanion copyWith({
    Value<String>? odooUserId,
    Value<String?>? etag,
    Value<DateTime?>? lastModified,
    Value<int?>? totalCount,
    Value<DateTime?>? lastFullFetchAt,
    Value<int>? rowid,
  }) {
    return CacheMetadataCompanion(
      odooUserId: odooUserId ?? this.odooUserId,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      totalCount: totalCount ?? this.totalCount,
      lastFullFetchAt: lastFullFetchAt ?? this.lastFullFetchAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (odooUserId.present) {
      map['user_id'] = Variable<String>(odooUserId.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (totalCount.present) {
      map['total_count'] = Variable<int>(totalCount.value);
    }
    if (lastFullFetchAt.present) {
      map['last_full_fetch_at'] = Variable<DateTime>(lastFullFetchAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataCompanion(')
          ..write('odooUserId: $odooUserId, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('totalCount: $totalCount, ')
          ..write('lastFullFetchAt: $lastFullFetchAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedTranscriptsTable cachedTranscripts =
      $CachedTranscriptsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CacheMetadataTable cacheMetadata = $CacheMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedTranscripts,
    syncQueue,
    cacheMetadata,
  ];
}

typedef $$CachedTranscriptsTableCreateCompanionBuilder =
    CachedTranscriptsCompanion Function({
      required String id,
      required String odooUserId,
      required String transcriptText,
      Value<double?> confidence,
      Value<double?> durationSeconds,
      Value<String?> audioUrl,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime lastFetchedAt,
      Value<DateTime?> lastAccessedAt,
      Value<bool> isOptimistic,
      Value<bool> isSynced,
      Value<String?> tempId,
      Value<int> rowid,
    });
typedef $$CachedTranscriptsTableUpdateCompanionBuilder =
    CachedTranscriptsCompanion Function({
      Value<String> id,
      Value<String> odooUserId,
      Value<String> transcriptText,
      Value<double?> confidence,
      Value<double?> durationSeconds,
      Value<String?> audioUrl,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> lastFetchedAt,
      Value<DateTime?> lastAccessedAt,
      Value<bool> isOptimistic,
      Value<bool> isSynced,
      Value<String?> tempId,
      Value<int> rowid,
    });

class $$CachedTranscriptsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTranscriptsTable> {
  $$CachedTranscriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcriptText => $composableBuilder(
    column: $table.transcriptText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOptimistic => $composableBuilder(
    column: $table.isOptimistic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedTranscriptsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTranscriptsTable> {
  $$CachedTranscriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcriptText => $composableBuilder(
    column: $table.transcriptText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOptimistic => $composableBuilder(
    column: $table.isOptimistic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedTranscriptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTranscriptsTable> {
  $$CachedTranscriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transcriptText => $composableBuilder(
    column: $table.transcriptText,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOptimistic => $composableBuilder(
    column: $table.isOptimistic,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get tempId =>
      $composableBuilder(column: $table.tempId, builder: (column) => column);
}

class $$CachedTranscriptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTranscriptsTable,
          CachedTranscriptEntry,
          $$CachedTranscriptsTableFilterComposer,
          $$CachedTranscriptsTableOrderingComposer,
          $$CachedTranscriptsTableAnnotationComposer,
          $$CachedTranscriptsTableCreateCompanionBuilder,
          $$CachedTranscriptsTableUpdateCompanionBuilder,
          (
            CachedTranscriptEntry,
            BaseReferences<
              _$AppDatabase,
              $CachedTranscriptsTable,
              CachedTranscriptEntry
            >,
          ),
          CachedTranscriptEntry,
          PrefetchHooks Function()
        > {
  $$CachedTranscriptsTableTableManager(
    _$AppDatabase db,
    $CachedTranscriptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTranscriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTranscriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTranscriptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> odooUserId = const Value.absent(),
                Value<String> transcriptText = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<double?> durationSeconds = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> lastFetchedAt = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
                Value<bool> isOptimistic = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> tempId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedTranscriptsCompanion(
                id: id,
                odooUserId: odooUserId,
                transcriptText: transcriptText,
                confidence: confidence,
                durationSeconds: durationSeconds,
                audioUrl: audioUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastFetchedAt: lastFetchedAt,
                lastAccessedAt: lastAccessedAt,
                isOptimistic: isOptimistic,
                isSynced: isSynced,
                tempId: tempId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String odooUserId,
                required String transcriptText,
                Value<double?> confidence = const Value.absent(),
                Value<double?> durationSeconds = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime lastFetchedAt,
                Value<DateTime?> lastAccessedAt = const Value.absent(),
                Value<bool> isOptimistic = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> tempId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedTranscriptsCompanion.insert(
                id: id,
                odooUserId: odooUserId,
                transcriptText: transcriptText,
                confidence: confidence,
                durationSeconds: durationSeconds,
                audioUrl: audioUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastFetchedAt: lastFetchedAt,
                lastAccessedAt: lastAccessedAt,
                isOptimistic: isOptimistic,
                isSynced: isSynced,
                tempId: tempId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedTranscriptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTranscriptsTable,
      CachedTranscriptEntry,
      $$CachedTranscriptsTableFilterComposer,
      $$CachedTranscriptsTableOrderingComposer,
      $$CachedTranscriptsTableAnnotationComposer,
      $$CachedTranscriptsTableCreateCompanionBuilder,
      $$CachedTranscriptsTableUpdateCompanionBuilder,
      (
        CachedTranscriptEntry,
        BaseReferences<
          _$AppDatabase,
          $CachedTranscriptsTable,
          CachedTranscriptEntry
        >,
      ),
      CachedTranscriptEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String odooUserId,
      required String operation,
      required String payload,
      Value<String?> tempId,
      Value<int> retryCount,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> odooUserId,
      Value<String> operation,
      Value<String> payload,
      Value<String?> tempId,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastError,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get tempId =>
      $composableBuilder(column: $table.tempId, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueEntry,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> odooUserId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> tempId = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                odooUserId: odooUserId,
                operation: operation,
                payload: payload,
                tempId: tempId,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String odooUserId,
                required String operation,
                required String payload,
                Value<String?> tempId = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                odooUserId: odooUserId,
                operation: operation,
                payload: payload,
                tempId: tempId,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueEntry,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$CacheMetadataTableCreateCompanionBuilder =
    CacheMetadataCompanion Function({
      required String odooUserId,
      Value<String?> etag,
      Value<DateTime?> lastModified,
      Value<int?> totalCount,
      Value<DateTime?> lastFullFetchAt,
      Value<int> rowid,
    });
typedef $$CacheMetadataTableUpdateCompanionBuilder =
    CacheMetadataCompanion Function({
      Value<String> odooUserId,
      Value<String?> etag,
      Value<DateTime?> lastModified,
      Value<int?> totalCount,
      Value<DateTime?> lastFullFetchAt,
      Value<int> rowid,
    });

class $$CacheMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFullFetchAt => $composableBuilder(
    column: $table.lastFullFetchAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFullFetchAt => $composableBuilder(
    column: $table.lastFullFetchAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get odooUserId => $composableBuilder(
    column: $table.odooUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFullFetchAt => $composableBuilder(
    column: $table.lastFullFetchAt,
    builder: (column) => column,
  );
}

class $$CacheMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheMetadataTable,
          CacheMetadataEntry,
          $$CacheMetadataTableFilterComposer,
          $$CacheMetadataTableOrderingComposer,
          $$CacheMetadataTableAnnotationComposer,
          $$CacheMetadataTableCreateCompanionBuilder,
          $$CacheMetadataTableUpdateCompanionBuilder,
          (
            CacheMetadataEntry,
            BaseReferences<
              _$AppDatabase,
              $CacheMetadataTable,
              CacheMetadataEntry
            >,
          ),
          CacheMetadataEntry,
          PrefetchHooks Function()
        > {
  $$CacheMetadataTableTableManager(_$AppDatabase db, $CacheMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> odooUserId = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime?> lastModified = const Value.absent(),
                Value<int?> totalCount = const Value.absent(),
                Value<DateTime?> lastFullFetchAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheMetadataCompanion(
                odooUserId: odooUserId,
                etag: etag,
                lastModified: lastModified,
                totalCount: totalCount,
                lastFullFetchAt: lastFullFetchAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String odooUserId,
                Value<String?> etag = const Value.absent(),
                Value<DateTime?> lastModified = const Value.absent(),
                Value<int?> totalCount = const Value.absent(),
                Value<DateTime?> lastFullFetchAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheMetadataCompanion.insert(
                odooUserId: odooUserId,
                etag: etag,
                lastModified: lastModified,
                totalCount: totalCount,
                lastFullFetchAt: lastFullFetchAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheMetadataTable,
      CacheMetadataEntry,
      $$CacheMetadataTableFilterComposer,
      $$CacheMetadataTableOrderingComposer,
      $$CacheMetadataTableAnnotationComposer,
      $$CacheMetadataTableCreateCompanionBuilder,
      $$CacheMetadataTableUpdateCompanionBuilder,
      (
        CacheMetadataEntry,
        BaseReferences<_$AppDatabase, $CacheMetadataTable, CacheMetadataEntry>,
      ),
      CacheMetadataEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedTranscriptsTableTableManager get cachedTranscripts =>
      $$CachedTranscriptsTableTableManager(_db, _db.cachedTranscripts);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CacheMetadataTableTableManager get cacheMetadata =>
      $$CacheMetadataTableTableManager(_db, _db.cacheMetadata);
}
