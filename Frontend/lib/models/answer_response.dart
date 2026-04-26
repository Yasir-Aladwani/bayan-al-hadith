class HadithSource {
  final String text;
  final String narrator;
  final String scholar;
  final String source;
  final String grade;

  const HadithSource({
    required this.text,
    required this.narrator,
    this.scholar = '',
    required this.source,
    required this.grade,
  });

  factory HadithSource.fromJson(Map<String, dynamic> json) {
    return HadithSource(
      text: json['text'] ?? '',
      narrator: json['narrator'] ?? '',
      scholar: json['scholar'] ?? '',
      source: json['source'] ?? '',
      grade: json['grade'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'narrator': narrator,
    'scholar': scholar,
    'source': source,
    'grade': grade,
  };
}

class AnswerResponse {
  final String answer;
  final List<HadithSource> sources;
  final String keywordUsed;
  final int totalRetrieved;
  final int totalAfterFilter;

  const AnswerResponse({
    required this.answer,
    required this.sources,
    this.keywordUsed = '',
    this.totalRetrieved = 0,
    this.totalAfterFilter = 0,
  });

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      answer: json['answer'] ?? '',
      // backend sends 'hadiths'; fall back to 'sources' for Firestore-persisted messages
      sources: (json['hadiths'] as List? ?? json['sources'] as List? ?? [])
          .map((s) => HadithSource.fromJson(s as Map<String, dynamic>))
          .toList(),
      keywordUsed: json['keyword_used'] ?? '',
      totalRetrieved: json['total_retrieved'] ?? 0,
      totalAfterFilter: json['total_after_filter'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'answer': answer,
    'sources': sources.map((s) => s.toMap()).toList(),
    'keyword_used': keywordUsed,
    'total_retrieved': totalRetrieved,
    'total_after_filter': totalAfterFilter,
  };
}

enum MessageType { user, assistant, error }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final AnswerResponse? response;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.response,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    if (response != null) 'response': response!.toMap(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] as String,
    text: map['text'] as String,
    type: MessageType.values.byName(map['type'] as String),
    timestamp: DateTime.parse(map['timestamp'] as String),
    response: map['response'] != null
        ? AnswerResponse.fromJson(map['response'] as Map<String, dynamic>)
        : null,
  );
}
