import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/model/transcript_item.dart';

/// Local cache service for storing transcripts on device.
/// Reduces network requests and enables offline access to history.
class TranscriptCacheService {
  static const String _cacheKey = 'cached_transcripts';
  static const String _cacheTimestampKey = 'cached_transcripts_timestamp';
  static const String _cacheTotalKey = 'cached_transcripts_total';
  
  /// Cache expiry time in minutes.
  /// After this time, fresh data will be fetched from server.
  static const int cacheExpiryMinutes = 5;

  /// Save transcripts to local storage.
  Future<void> cacheTranscripts(List<TranscriptItem> transcripts, int total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final List<Map<String, dynamic>> jsonList = transcripts.map((t) => {
        'id': t.id,
        'text': t.text,
        'created_at': t.createdAt.toIso8601String(),
        'confidence': t.confidence,
        'duration_seconds': t.durationSeconds,
        'audio_url': t.audioUrl,
      }).toList();
      
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_cacheTotalKey, total);
      
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE: Saved ${transcripts.length} transcripts to local storage');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE ERROR: Failed to save transcripts: $e');
      }
    }
  }

  /// Retrieve cached transcripts from local storage.
  /// Returns null if cache is empty or expired.
  Future<CachedTranscripts?> getCachedTranscripts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? cachedJson = prefs.getString(_cacheKey);
      final int? timestamp = prefs.getInt(_cacheTimestampKey);
      final int? total = prefs.getInt(_cacheTotalKey);
      
      if (cachedJson == null || timestamp == null) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('CACHE: No cached transcripts found');
        }
        return null;
      }
      
      // Check if cache is expired
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);
      
      if (difference.inMinutes > cacheExpiryMinutes) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('CACHE: Cache expired (${difference.inMinutes} min old)');
        }
        return null;
      }
      
      final List<dynamic> jsonList = jsonDecode(cachedJson) as List<dynamic>;
      final List<TranscriptItem> transcripts = jsonList
          .map((json) => TranscriptItem.fromJson(json as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE: Loaded ${transcripts.length} transcripts from cache (${difference.inSeconds}s old)');
      }
      
      return CachedTranscripts(
        items: transcripts,
        total: total ?? transcripts.length,
        cachedAt: cacheTime,
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE ERROR: Failed to load transcripts: $e');
      }
      return null;
    }
  }

  /// Add a single transcript to the cache (for newly created ones).
  Future<void> addTranscriptToCache(TranscriptItem transcript) async {
    try {
      final cached = await getCachedTranscripts();
      final List<TranscriptItem> items = cached?.items.toList() ?? [];
      
      // Add to beginning (newest first)
      items.insert(0, transcript);
      
      // Keep cache size reasonable (max 100 items)
      if (items.length > 100) {
        items.removeRange(100, items.length);
      }
      
      await cacheTranscripts(items, (cached?.total ?? 0) + 1);
      
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE: Added new transcript to cache');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE ERROR: Failed to add transcript: $e');
      }
    }
  }

  /// Clear all cached transcripts.
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_cacheTotalKey);
      
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE: Cleared transcript cache');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE ERROR: Failed to clear cache: $e');
      }
    }
  }

  /// Invalidate cache (forces refresh on next fetch).
  Future<void> invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheTimestampKey);
      
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE: Invalidated cache timestamp');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CACHE ERROR: Failed to invalidate cache: $e');
      }
    }
  }
}

/// Cached transcripts with metadata.
class CachedTranscripts {
  const CachedTranscripts({
    required this.items,
    required this.total,
    required this.cachedAt,
  });

  final List<TranscriptItem> items;
  final int total;
  final DateTime cachedAt;
}
