import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class OtpService {
  static Future<void> send(String email, {bool isPasswordReset = false}) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'is_password_reset': isPasswordReset,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'فشل إرسال الرمز');
    }
  }

  static Future<bool> verify(String email, String code) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['valid'] == true;
    }
    return false;
  }

  static void clear() {}
}
