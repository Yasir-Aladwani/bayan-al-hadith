import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class OtpService {
  static const _serviceId          = 'service_jkytisf';
  static const _templateId         = 'template_k7xkcw1';
  static const _templateIdPassword = 'template_n4x7r8o';
  static const _publicKey          = '-DSdH0pq5_Rkq5s0E';
  static const _privateKey         = 'agdLoKNIJn2oCnO2fZ9M6';

  static String? _code;
  static DateTime? _expiry;

  static Future<void> send(String email, {bool isPasswordReset = false}) async {
    _code   = (100000 + Random().nextInt(900000)).toString();
    _expiry = DateTime.now().add(const Duration(minutes: 10));

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id':   _serviceId,
        'template_id':  isPasswordReset ? _templateIdPassword : _templateId,
        'user_id':      _publicKey,
        'accessToken':  _privateKey,
        'template_params': {
          'email':    email,
          'passcode': _code,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('EmailJS error ${response.statusCode}: ${response.body}');
    }
  }

  static bool verify(String input) {
    if (_code == null || _expiry == null) return false;
    if (DateTime.now().isAfter(_expiry!)) return false;
    return input.trim() == _code;
  }

  static void clear() {
    _code   = null;
    _expiry = null;
  }
}
