import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_font.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/otp_service.dart';
import 'otp_screen.dart';

const _accent = Color(0xFFC4A882);

Color _bg(BuildContext ctx)       => Theme.of(ctx).scaffoldBackgroundColor;
Color _card(BuildContext ctx)     => Theme.of(ctx).cardColor;
Color _border(BuildContext ctx)   => Theme.of(ctx).dividerColor;
Color _textMain(BuildContext ctx) => Theme.of(ctx).colorScheme.onSurface;
Color _textMute(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF9E8468)
    : const Color(0xFF8B7355);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'يرجى إدخال البريد الإلكتروني');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await OtpService.send(email, isPasswordReset: true);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: email,
              password: '',
              name: '',
              onVerified: () => _resetPassword(email),
            ),
          ),
        );
      }
    } catch (_) {
      setState(() => _error = 'فشل إرسال الرمز، تحقق من الإيميل وحاول مجدداً');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset('assets/logo.png', height: 100, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  Text('استعادة كلمة المرور',
                      style: appFont(
                          color: _textMain(context), fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('أدخل بريدك الإلكتروني وسنرسل لك رمز التحقق',
                      style: appFont(color: _textMute(context), fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _card(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border(context)),
                      boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _bg(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border(context)),
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.rtl,
                            style: appFont(color: _textMain(context), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'البريد الإلكتروني',
                              hintStyle: appFont(color: _textMute(context), fontSize: 14),
                              prefixIcon: Icon(Icons.email_outlined, color: _textMute(context), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: appFont(color: Colors.red, fontSize: 13)),
                        ],

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : Text('إرسال رمز التحقق',
                                    style: appFont(
                                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('رجوع',
                        style: appFont(color: _textMute(context), fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
