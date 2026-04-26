import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_font.dart';
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'يرجى تعبئة جميع الحقول');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'كلمة المرور غير متطابقة');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await OtpService.send(email);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(email: email, password: password, name: name),
          ),
        );
      }
    } catch (_) {
      setState(() => _error = 'فشل إرسال الرمز، تحقق من الإيميل وحاول مجدداً');
    } finally {
      if (mounted) setState(() => _loading = false);
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 100, fit: BoxFit.contain),
                const SizedBox(height: 10),
                Text('مساعد الحديث النبوي',
                    style: appFont(color: _textMute(context), fontSize: 13)),
                const SizedBox(height: 6),
                Container(height: 1, width: 80, color: _accent.withValues(alpha: 0.35)),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _card(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border(context)),
                    boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إنشاء حساب',
                          style: appFont(color: _textMain(context), fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('أهلاً بك، أنشئ حسابك للبدء',
                          style: appFont(color: _textMute(context), fontSize: 13)),
                      const SizedBox(height: 14),

                      _InputField(hint: 'الاسم', icon: Icons.person_outline, controller: _nameController),
                      const SizedBox(height: 12),
                      _InputField(hint: 'البريد الإلكتروني', icon: Icons.email_outlined, controller: _emailController),
                      const SizedBox(height: 12),
                      _InputField(hint: 'كلمة المرور', icon: Icons.lock_outline, isPassword: true, controller: _passwordController),
                      const SizedBox(height: 12),
                      _InputField(hint: 'تأكيد كلمة المرور', icon: Icons.lock_outline, isPassword: true, controller: _confirmController),

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: appFont(color: Colors.red, fontSize: 13)),
                      ],

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : Text('إنشاء الحساب',
                                  style: appFont(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('لديك حساب؟ سجّل دخولك',
                      style: appFont(
                        color: _accent, fontSize: 14, fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline, decorationColor: _accent,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  const _InputField({required this.hint, required this.icon, required this.controller, this.isPassword = false});

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border(context)),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        textDirection: TextDirection.rtl,
        style: appFont(color: _textMain(context), fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: appFont(color: _textMute(context), fontSize: 14),
          prefixIcon: Icon(widget.icon, color: _textMute(context), size: 20),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: _textMute(context), size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
