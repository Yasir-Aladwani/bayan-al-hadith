import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/answer_response.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static Future<AnswerResponse> ask(String question) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ask'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({'question': question}),
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      return AnswerResponse.fromJson(jsonDecode(decoded));
    } else {
      final decoded = utf8.decode(response.bodyBytes);
      final error = jsonDecode(decoded);
      throw Exception(error['detail'] ?? 'خطأ في الاتصال بالخادم');
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
