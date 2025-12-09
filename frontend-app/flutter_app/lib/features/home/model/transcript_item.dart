class TranscriptItem {
  const TranscriptItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.confidence,
    this.durationSeconds,
    this.audioUrl,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final double? confidence;
  final double? durationSeconds;
  final String? audioUrl;

  factory TranscriptItem.fromJson(Map<String, dynamic> json) {
    return TranscriptItem(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      confidence: (json['confidence'] as num?)?.toDouble(),
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
      audioUrl: json['audio_url'] as String?,
    );
  }
}
