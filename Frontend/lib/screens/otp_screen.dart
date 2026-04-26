import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_font.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/otp_service.dart';
import 'chat_screen.dart';

const _accent = Color(0xFFC4A882);

Color _bg(BuildContext ctx)       => Theme.of(ctx).scaffoldBackgroundColor;
Color _card(BuildContext ctx)     => Theme.of(ctx).cardColor;
Color _border(BuildContext ctx)   => Theme.of(ctx).dividerColor;
Color _textMain(BuildContext ctx) => Theme.of(ctx).colorScheme.onSurface;
Color _textMute(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF9E8468)
    : const Color(0xFF8B7355);

class OtpScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final Future<void> Function()? onVerified;

  const OtpScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    this.onVerified,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  bool _loading     = false;
  bool _resending   = false;
  String? _error;

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'أدخل الرمز المكون من 6 أرقام');
      return;
    }

    if (!OtpService.verify(code)) {
      setState(() => _error = 'الرمز غير صحيح أو انتهت صلاحيته');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      if (widget.onVerified != null) {
        await widget.onVerified!();
        OtpService.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم التحقق! راجع بريدك لإعادة تعيين كلمة المرور (قد تجدها في Spam)',
                style: appFont()),
            backgroundColor: _accent,
            duration: const Duration(seconds: 5),
          ));
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );
        await cred.user?.updateDisplayName(widget.name);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'name':      widget.name,
          'email':     widget.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        await context.read<UserProvider>().reload();
        OtpService.clear();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
            (_) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _firebaseError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      await OtpService.send(widget.email);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم إعادة إرسال الرمز إلى ${widget.email}',
              style: appFont()),
          backgroundColor: _accent,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'فشل إرسال الرمز، حاول مجدداً');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String _firebaseError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'البريد الإلكتروني مستخدم مسبقاً';
      default: return 'حدث خطأ، حاول مجدداً';
    }
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Image.asset('assets/logo.png', height: 100, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  Text('التحقق من البريد',
                      style: appFont(
                          color: _textMain(context), fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('أرسلنا رمز التحقق إلى',
                      style: appFont(color: _textMute(context), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(widget.email,
                      style: appFont(color: _accent, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _card(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border(context)),
                      boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        AutofillGroup(
                          child: TextField(
                            controller: _controller,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: appFont(
                                color: _textMain(context), fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 10),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '000000',
                              hintStyle: appFont(
                                  color: _textMute(context).withValues(alpha: 0.4), fontSize: 28, letterSpacing: 10),
                              filled: true,
                              fillColor: _bg(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _border(context)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _accent, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _border(context)),
                              ),
                            ),
                            onSubmitted: (_) => _verify(),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: appFont(color: Colors.red, fontSize: 13),
                              textAlign: TextAlign.center),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _verify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : Text('تحقق',
                                    style: appFont(
                                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _resending ? null : _resend,
                    child: _resending
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                        : Text('لم يصلك الرمز؟ إعادة الإرسال',
                            style: appFont(
                              color: _accent, fontSize: 14, fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline, decorationColor: _accent,
                            )),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('رجوع',
                        style: appFont(color: _textMute(context), fontSize: 14)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
