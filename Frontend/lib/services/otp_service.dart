import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class OtpService {
  static const _serviceId           = String.fromEnvironment('EMAILJS_SERVICE_ID');
  static const _templateId          = String.fromEnvironment('EMAILJS_TEMPLATE_ID');
  static const _templateIdPassword  = String.fromEnvironment('EMAILJS_TEMPLATE_ID_PASSWORD');
  static const _publicKey           = String.fromEnvironment('EMAILJS_PUBLIC_KEY');

  static String?   _pendingCode;
  static String?   _pendingEmail;
  static DateTime? _expiry;

  static Future<void> send(String email, {bool isPasswordReset = false}) async {
    final code = (100000 + Random().nextInt(900000)).toString();
    _pendingCode  = code;
    _pendingEmail = email;
    _expiry       = DateTime.now().add(const Duration(minutes: 10));

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id':  _serviceId,
        'template_id': isPasswordReset ? _templateIdPassword : _templateId,
        'user_id':     _publicKey,
        'template_params': {'email': email, 'passcode': code},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل إرسال الرمز');
    }
  }

  static Future<bool> verify(String email, String code) async {
    if (_pendingEmail != email)  return false;
    if (_pendingCode  == null)   return false;
    if (_expiry == null || DateTime.now().isAfter(_expiry!)) return false;
    return _pendingCode == code.trim();
  }

  static void clear() {
    _pendingCode  = null;
    _pendingEmail = null;
    _expiry       = null;
  }
}
