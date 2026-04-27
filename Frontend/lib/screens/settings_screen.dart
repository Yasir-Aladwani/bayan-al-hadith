import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/app_font.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

Color _accent(BuildContext ctx)   => Theme.of(ctx).colorScheme.primary;
Color _bg(BuildContext ctx)       => Theme.of(ctx).scaffoldBackgroundColor;
Color _card(BuildContext ctx)     => Theme.of(ctx).cardColor;
Color _border(BuildContext ctx)   => Theme.of(ctx).dividerColor;
Color _textMain(BuildContext ctx) => Theme.of(ctx).colorScheme.onSurface;
Color _textMute(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF9E8468)
    : const Color(0xFF8B7355);

void _showContactDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: _card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent(context).withValues(alpha: 0.12),
                  border: Border.all(color: _accent(context), width: 2),
                ),
                child: Icon(Icons.support_agent_outlined, color: _accent(context), size: 34),
              ),
              const SizedBox(height: 16),
              Text('تواصل معنا',
                  style: appFont(color: _textMain(context), fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('نسعد بتواصلك معنا في أي وقت',
                  style: appFont(color: _textMute(context), fontSize: 13)),
              const SizedBox(height: 20),
              Container(width: double.infinity, height: 1, color: _border(context)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _bg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border(context)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: _accent(context), size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('البريد الإلكتروني',
                            style: appFont(color: _textMute(context), fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('hudaiapp1@gmail.com',
                            style: appFont(color: _textMain(context), fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(width: double.infinity, height: 1, color: _border(context)),
              const SizedBox(height: 20),
              Text('سنرد عليك في أقرب وقت ممكن',
                  style: appFont(color: _textMute(context), fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('حسناً',
                      style: appFont(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: _card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent(context).withValues(alpha: 0.12),
                  border: Border.all(color: _accent(context), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              Text('هداي',
                  style: appFont(color: _textMain(context), fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('الإصدار 1.0.0',
                  style: appFont(color: _textMute(context), fontSize: 13)),
              const SizedBox(height: 20),
              Container(width: double.infinity, height: 1, color: _border(context)),
              const SizedBox(height: 20),
              Text(
                'هداي.. مساعدك الذكي الذي يجمع بين أصالة المصدر وذكاء التكنولوجيا. رفيقك الموثوق للبحث في الحديث وفهم القرآن، وملاذك الدافئ الذي يواسيك بآيات السكينة وأحاديث الطمأنينة، ليقدم لك الدعم الوجداني ويرشدك بكلماتٍ تمس قلبك وتجبر خاطرك برؤية معاصرة ومنهجية رصينة.',
                textAlign: TextAlign.center,
                style: appFont(color: _textMain(context), fontSize: 14, height: 1.7),
              ),
              const SizedBox(height: 20),
              Container(width: double.infinity, height: 1, color: _border(context)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: _accent(context), size: 14),
                  const SizedBox(width: 6),
                  Text('صُنع بشغف لخدمة المسلمين',
                      style: appFont(color: _textMute(context), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('حسناً',
                      style: appFont(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showDeleteAccountDialog(BuildContext context) async {
  final passwordCtrl = TextEditingController();
  String? error;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _card(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('حذف الحساب',
              style: appFont(color: Colors.red, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سيتم حذف حسابك نهائياً ولا يمكن التراجع عن هذا الإجراء.',
                    style: appFont(color: _textMute(context), fontSize: 13)),
                const SizedBox(height: 16),
                _DialogField(hint: 'كلمة المرور للتأكيد', controller: passwordCtrl, isPassword: true),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: appFont(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: appFont(color: _textMute(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                final password = passwordCtrl.text.trim();
                if (password.isEmpty) {
                  if (ctx.mounted) setState(() => error = 'يرجى إدخال كلمة المرور');
                  return;
                }
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: password,
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.delete();
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on FirebaseAuthException catch (e) {
                  if (ctx.mounted) {
                    setState(() {
                      error = e.code == 'wrong-password' || e.code == 'invalid-credential'
                          ? 'كلمة المرور غير صحيحة'
                          : 'حدث خطأ، حاول مجدداً';
                    });
                  }
                }
              },
              child: Text('حذف الحساب',
                  style: appFont(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ),
  );

  passwordCtrl.dispose();

  if (confirmed == true && context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

Future<void> _showChangePasswordDialog(BuildContext context) async {
  final currentCtrl = TextEditingController();
  final newCtrl     = TextEditingController();
  final confirmCtrl = TextEditingController();
  String? error;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _card(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('تغيير كلمة المرور',
              style: appFont(color: _textMain(context), fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(hint: 'كلمة المرور الحالية', controller: currentCtrl, isPassword: true),
                const SizedBox(height: 12),
                _DialogField(hint: 'كلمة المرور الجديدة', controller: newCtrl, isPassword: true),
                const SizedBox(height: 12),
                _DialogField(hint: 'تأكيد كلمة المرور الجديدة', controller: confirmCtrl, isPassword: true),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: appFont(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: appFont(color: _textMute(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                final current = currentCtrl.text.trim();
                final newPass = newCtrl.text.trim();
                final confirm = confirmCtrl.text.trim();

                if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                  setState(() => error = 'يرجى تعبئة جميع الحقول');
                  return;
                }
                if (newPass.length < 6) {
                  setState(() => error = 'كلمة المرور الجديدة 6 أحرف على الأقل');
                  return;
                }
                if (newPass != confirm) {
                  setState(() => error = 'كلمتا المرور غير متطابقتين');
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: current,
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPass);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تم تغيير كلمة المرور بنجاح', style: appFont()),
                      backgroundColor: _accent(context),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                } on FirebaseAuthException catch (e) {
                  setState(() {
                    error = e.code == 'wrong-password' || e.code == 'invalid-credential'
                        ? 'كلمة المرور الحالية غير صحيحة'
                        : 'حدث خطأ، حاول مجدداً';
                  });
                }
              },
              child: Text('حفظ', style: appFont(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ),
  );

  currentCtrl.dispose();
  newCtrl.dispose();
  confirmCtrl.dispose();
}

class _DialogField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  const _DialogField({required this.hint, required this.controller, this.isPassword = false});

  @override
  State<_DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<_DialogField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border(context)),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        textDirection: TextDirection.rtl,
        style: appFont(color: _textMain(context), fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: appFont(color: _textMute(context), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _textMute(context), size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user     = FirebaseAuth.instance.currentUser;
    final name     = user?.displayName ?? 'ضيف';
    final email    = user?.email ?? '';
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        centerTitle: true,
        title: Text('الإعدادات',
            style: appFont(color: _textMain(context), fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textMain(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── بطاقة المستخدم ──────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent(context).withValues(alpha: 0.12),
                      border: Border.all(color: _accent(context), width: 2),
                    ),
                    child: Icon(Icons.person_outline, color: _accent(context), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: appFont(color: _textMain(context), fontSize: 16, fontWeight: FontWeight.w700)),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(email, style: appFont(color: _textMute(context), fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── المظهر ──────────────────────────
            _SectionLabel('المظهر', context),
            const SizedBox(height: 10),

            // اختيار الثيم (3 أزرار)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: _accent(context), size: 20),
                      const SizedBox(width: 12),
                      Text('مظهر التطبيق',
                          style: appFont(color: _textMain(context), fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ThemeModeBtn(label: 'فاتح',  icon: Icons.light_mode_outlined, mode: 0, current: settings.themeMode, onTap: () => settings.setThemeMode(0), context: context),
                      const SizedBox(width: 8),
                      _ThemeModeBtn(label: 'داكن',  icon: Icons.dark_mode_outlined,  mode: 1, current: settings.themeMode, onTap: () => settings.setThemeMode(1), context: context),
                      const SizedBox(width: 8),
                      _ThemeModeBtn(label: 'أسود',  icon: Icons.circle,              mode: 2, current: settings.themeMode, onTap: () => settings.setThemeMode(2), context: context),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // حجم الخط
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_fields, color: _accent(context), size: 20),
                      const SizedBox(width: 12),
                      Text('حجم الخط',
                          style: appFont(color: _textMain(context), fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _FontSizeBtn(label: 'صغير', scale: 0.85,  current: settings.fontScale, onTap: () => settings.setFontScale(0.85),  context: context),
                      const SizedBox(width: 8),
                      _FontSizeBtn(label: 'وسط',  scale: 1.0,   current: settings.fontScale, onTap: () => settings.setFontScale(1.0),   context: context),
                      const SizedBox(width: 8),
                      _FontSizeBtn(label: 'كبير', scale: 1.15,  current: settings.fontScale, onTap: () => settings.setFontScale(1.15),  context: context),
                      const SizedBox(width: 8),
                      _FontSizeBtn(label: 'أكبر', scale: 1.3,   current: settings.fontScale, onTap: () => settings.setFontScale(1.3),   context: context),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // نوع الخط
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.font_download_outlined, color: _accent(context), size: 20),
                      const SizedBox(width: 12),
                      Text('نوع الخط',
                          style: appFont(color: _textMain(context), fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: kArabicFonts.asMap().entries.map((entry) {
                      final i    = entry.key;
                      final font = entry.value;
                      final isSelected = settings.fontFamily == font['family'];
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => settings.setFontFamily(font['family']!),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _accent(context) : _bg(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? _accent(context) : _border(context),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(font['name']!,
                                      textAlign: TextAlign.center,
                                      style: appFont(
                                          color: isSelected ? Colors.white : _textMute(context),
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                                ),
                              ),
                            ),
                            if (i < kArabicFonts.length - 1) const SizedBox(width: 8),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _bg(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border(context)),
                    ),
                    child: Text(
                      'بسم الله الرحمن الرحيم',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        settings.fontFamily,
                        color: _textMain(context),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── الحساب ──────────────────────────
            _SectionLabel('الحساب', context),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.lock_outline,
              label: 'تغيير كلمة المرور',
              onTap: () => _showChangePasswordDialog(context),
              context: context,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    settings.notificationsEnabled
                        ? Icons.notifications_outlined
                        : Icons.notifications_off_outlined,
                    color: _accent(context), size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('الإشعارات',
                        style: appFont(color: _textMain(context), fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Switch(
                    value: settings.notificationsEnabled,
                    onChanged: (_) => settings.toggleNotifications(),
                    activeThumbColor: _accent(context),
                    activeTrackColor: _accent(context).withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            if (user != null && user.email != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showDeleteAccountDialog(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('حذف الحساب',
                            style: appFont(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.red.withValues(alpha: 0.5), size: 14),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── التطبيق ──────────────────────────
            _SectionLabel('التطبيق', context),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.info_outline,
              label: 'عن التطبيق',
              onTap: () => _showAboutDialog(context),
              context: context,
            ),
            _SettingsTile(
              icon: Icons.mail_outline,
              label: 'تواصل معنا',
              onTap: () => _showContactDialog(context),
              context: context,
            ),

            if (user != null) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Text('تسجيل الخروج',
                          style: appFont(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],

            // ── الأدمن ───────────────────────────
            if (context.watch<AdminProvider>().isAdmin) ...[
              const SizedBox(height: 28),
              _SectionLabel('الإدارة', context),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _accent(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent(context).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, color: _accent(context), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('لوحة الأدمن',
                            style: appFont(color: _accent(context), fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.arrow_forward_ios, color: _accent(context).withValues(alpha: 0.6), size: 14),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final BuildContext ctx;
  const _SectionLabel(this.text, this.ctx);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: appFont(color: _textMute(ctx), fontSize: 13, fontWeight: FontWeight.w600));
  }
}

class _ThemeModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final int mode;
  final int current;
  final VoidCallback onTap;
  final BuildContext context;

  const _ThemeModeBtn({
    required this.label,
    required this.icon,
    required this.mode,
    required this.current,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final isSelected = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _accent(context) : _bg(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _accent(context) : _border(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : _textMute(context),
                  size: 18),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: appFont(
                    color: isSelected ? Colors.white : _textMute(context),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSizeBtn extends StatelessWidget {
  final String label;
  final double scale;
  final double current;
  final VoidCallback onTap;
  final BuildContext context;

  const _FontSizeBtn({
    required this.label,
    required this.scale,
    required this.current,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final isSelected = (current - scale).abs() < 0.01;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _accent(context) : _bg(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _accent(context) : _border(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: appFont(
                color: isSelected ? Colors.white : _textMute(context),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final BuildContext context;

  const _SettingsTile({required this.icon, required this.label, required this.onTap, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accent(context), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: appFont(color: _textMain(context), fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.arrow_forward_ios, color: _textMute(context), size: 14),
          ],
        ),
      ),
    );
  }
}
