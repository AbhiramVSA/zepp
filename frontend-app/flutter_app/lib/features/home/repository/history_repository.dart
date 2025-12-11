import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/app_config.dart';
import '../model/transcript_item.dart';

class TranscriptHistory {
  const TranscriptHistory({required this.items, required this.total});

  final List<TranscriptItem> items;
  final int total;
}

class HistoryRepository {
  const HistoryRepository();

  Future<TranscriptHistory> fetchHistory({required String token, int limit = 50, int offset = 0}) async {
    // First, debug the token
    if (kDebugMode) {
      await _debugToken(token);
    }
    
    final uri = Uri.parse('$backendBaseUrl/transcripts/history?limit=$limit&offset=$offset');
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG History: GET $uri');
      print('DEBUG History: Token length: ${token.length}');
    }
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG History: Response status: ${response.statusCode}');
      print('DEBUG History: Response body: ${response.body}');
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

    return TranscriptHistory(items: items, total: total);
  }
  
  Future<void> _debugToken(String token) async {
    try {
      final uri = Uri.parse('$backendBaseUrl/auth/debug-token');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'token=$token',
      );
      // ignore: avoid_print
      print('DEBUG Token Test: ${response.statusCode}');
      // ignore: avoid_print
      print('DEBUG Token Result: ${response.body}');
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG Token Error: $e');
    }
  }
}
