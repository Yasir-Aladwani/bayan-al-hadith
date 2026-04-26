import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_font.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'chat_screen.dart';

const _accent = Color(0xFFC4A882);

Color _bg(BuildContext ctx)       => Theme.of(ctx).scaffoldBackgroundColor;
Color _card(BuildContext ctx)     => Theme.of(ctx).cardColor;
Color _border(BuildContext ctx)   => Theme.of(ctx).dividerColor;
Color _textMain(BuildContext ctx) => Theme.of(ctx).colorScheme.onSurface;
Color _textMute(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF9E8468)
    : const Color(0xFF8B7355);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'يرجى تعبئة جميع الحقول');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.data()?['isDisabled'] == true) {
          await FirebaseAuth.instance.signOut();
          setState(() => _error = 'هذا الحساب موقوف، تواصل مع الدعم');
          return;
        }
      }
      if (mounted) _goToChat(context, asGuest: false);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _errorMessage(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  String _errorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'invalid-email':      return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':      return 'الحساب موقوف';
      default:                   return 'حدث خطأ، حاول مجدداً';
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
            child: SingleChildScrollView(child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Image.asset('assets/logo.png', height: 90, fit: BoxFit.contain),
                Text('مساعد الحديث النبوي',
                    style: appFont(color: _textMute(context), fontSize: 13)),
                const SizedBox(height: 4),
                Container(height: 1, width: 80, color: _accent.withValues(alpha: 0.35)),
                const SizedBox(height: 12),

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
                      Text('تسجيل الدخول',
                          style: appFont(color: _textMain(context), fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('أهلاً بك، سجّل دخولك للمتابعة',
                          style: appFont(color: _textMute(context), fontSize: 13)),
                      const SizedBox(height: 14),

                      _InputField(hint: 'البريد الإلكتروني', icon: Icons.email_outlined, controller: _emailController),
                      const SizedBox(height: 14),
                      _InputField(hint: 'كلمة المرور', icon: Icons.lock_outline, isPassword: true, controller: _passwordController),

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: appFont(color: Colors.red, fontSize: 13)),
                      ],

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                          child: Text('نسيت كلمة المرور؟',
                              style: appFont(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _MainButton(label: _loading ? '...' : 'دخول', onTap: _loading ? () {} : _login),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(child: Divider(color: _border(context), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('أو', style: appFont(color: _textMute(context), fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: _border(context), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _SocialButton(
                        label: 'المتابعة بـ Google',
                        iconWidget: _GoogleIcon(),
                        onTap: () => _showComingSoon(context),
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        label: 'المتابعة بـ Apple',
                        iconWidget: Icon(Icons.apple, color: _textMain(context), size: 22),
                        onTap: () => _showComingSoon(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _goToChat(context, asGuest: true),
                  child: Text('المتابعة كضيف بدون تسجيل',
                      style: appFont(
                        color: _textMute(context), fontSize: 14,
                        decoration: TextDecoration.underline, decorationColor: _textMute(context),
                      )),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text('ليس لديك حساب؟ سجّل الآن',
                      style: appFont(
                        color: _accent, fontSize: 14, fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline, decorationColor: _accent,
                      )),
                ),
                const SizedBox(height: 12),
              ],
            )),
          ),
        ),
      ),
    );
  }

  void _goToChat(BuildContext context, {bool asGuest = false}) async {
    if (asGuest) await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
        (_) => false,
      );
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('قريباً إن شاء الله', style: appFont()),
      backgroundColor: const Color(0xFFC4A882),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _textMute(context),
                    size: 20,
                  ),
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

class _MainButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MainButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label,
            style: appFont(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.iconWidget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _border(context), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _bg(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(label,
                style: appFont(color: _textMain(context), fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Center(
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
