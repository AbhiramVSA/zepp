import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/app_config.dart';
import '../../../core/services/transcript_cache_service.dart';
import '../model/transcript_item.dart';

class TranscriptHistory {
  const TranscriptHistory({
    required this.items,
    required this.total,
    this.fromCache = false,
  });

  final List<TranscriptItem> items;
  final int total;
  final bool fromCache;
}

class HistoryRepository {
  HistoryRepository({TranscriptCacheService? cacheService})
      : _cacheService = cacheService ?? TranscriptCacheService();

  final TranscriptCacheService _cacheService;

  /// Fetch history with cache-first strategy.
  /// Returns cached data immediately if available, then optionally refreshes.
  Future<TranscriptHistory> fetchHistory({
    required String token,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // Try cache first (only for first page)
    if (!forceRefresh && offset == 0) {
      final cached = await _cacheService.getCachedTranscripts();
      if (cached != null) {
        return TranscriptHistory(
          items: cached.items,
          total: cached.total,
          fromCache: true,
        );
      }
    }

    // Fetch from server
    final result = await _fetchFromServer(token: token, limit: limit, offset: offset);

    // Cache first page results
    if (offset == 0) {
      await _cacheService.cacheTranscripts(result.items, result.total);
    }

    return result;
  }

  /// Force fetch from server (bypasses cache).
  Future<TranscriptHistory> refreshHistory({
    required String token,
    int limit = 50,
    int offset = 0,
  }) async {
    return fetchHistory(token: token, limit: limit, offset: offset, forceRefresh: true);
  }

  /// Add a new transcript to the local cache.
  Future<void> cacheNewTranscript(TranscriptItem transcript) async {
    await _cacheService.addTranscriptToCache(transcript);
  }

  /// Clear local cache (e.g., on logout).
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  /// Invalidate cache to force refresh on next fetch.
  Future<void> invalidateCache() async {
    await _cacheService.invalidateCache();
  }

  Future<TranscriptHistory> _fetchFromServer({
    required String token,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$backendBaseUrl/transcripts/history?limit=$limit&offset=$offset');
    if (kDebugMode) {
      // ignore: avoid_print
      print('HISTORY: Fetching from server $uri');
    }

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (kDebugMode) {
      // ignore: avoid_print
      print('HISTORY: Response status: ${response.statusCode}');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load history (${response.statusCode}): ${response.body}');
    }

    final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> rawItems = jsonBody['items'] as List<dynamic>? ?? <dynamic>[];
    final List<TranscriptItem> items = rawItems
        .map((e) => TranscriptItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final int total = (jsonBody['total'] as num?)?.toInt() ?? items.length;

    return TranscriptHistory(items: items, total: total, fromCache: false);
  }
}
