import 'dart:convert';

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
    final uri = Uri.parse('$backendBaseUrl/transcripts/history?limit=$limit&offset=$offset');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to load history (${response.statusCode})');
    }

    final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> rawItems = jsonBody['items'] as List<dynamic>? ?? <dynamic>[];
    final List<TranscriptItem> items = rawItems
        .map((e) => TranscriptItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final int total = (jsonBody['total'] as num?)?.toInt() ?? items.length;

    return TranscriptHistory(items: items, total: total);
  }
}
