import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_font.dart';
import 'complaints_screen.dart';

Color _accent(BuildContext ctx)   => Theme.of(ctx).colorScheme.primary;
Color _bg(BuildContext ctx)       => Theme.of(ctx).scaffoldBackgroundColor;
Color _card(BuildContext ctx)     => Theme.of(ctx).cardColor;
Color _border(BuildContext ctx)   => Theme.of(ctx).dividerColor;
Color _textMain(BuildContext ctx) => Theme.of(ctx).colorScheme.onSurface;
Color _textMute(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF9E8468)
    : const Color(0xFF8B7355);

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _toggleLock(String uid, bool isDisabled) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isDisabled': !isDisabled});
  }


  Future<void> _sendNotification(BuildContext context) async {
    final ctrl = TextEditingController();
    bool sent = false;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _card(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('إرسال إشعار',
              style: appFont(color: _textMain(context), fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            textDirection: TextDirection.rtl,
            style: appFont(color: _textMain(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'نص الإشعار...',
              hintStyle: appFont(color: _textMute(context), fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accent(context), width: 2)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: appFont(color: _textMute(context)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accent(context), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance.collection('notifications').add({
                    'message':   ctrl.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'sentBy':    FirebaseAuth.instance.currentUser?.uid,
                  });
                  sent = true;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text('إرسال',
                  style: appFont(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (sent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم إرسال الإشعار بنجاح', style: appFont(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        centerTitle: true,
        title: Text('لوحة الأدمن',
            style: appFont(color: _textMain(context), fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textMain(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collectionGroup('conversations').snapshots(),
              builder: (context, convsSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('complaints')
                      .where('isResolved', isEqualTo: false)
                      .snapshots(),
                  builder: (context, complaintsSnap) {

                    final loading = usersSnap.connectionState == ConnectionState.waiting;
                    if (loading) {
                      return Center(child: CircularProgressIndicator(color: _accent(context)));
                    }

                    final usersDocs = usersSnap.data?.docs ?? [];
                    final convsDocs = convsSnap.data?.docs ?? [];
                    final pendingComplaints = complaintsSnap.data?.docs.length ?? 0;

                    final convCountByUser = <String, int>{};
                    for (final doc in convsDocs) {
                      final uid = doc.reference.parent.parent?.id ?? '';
                      convCountByUser[uid] = (convCountByUser[uid] ?? 0) + 1;
                    }

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [

                        // ── الإحصائيات ──────────────────
                        _SectionLabel('الإحصائيات', context),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _StatCard(
                                icon: Icons.people_outline,
                                label: 'المستخدمون',
                                value: '${usersDocs.length}',
                                context: context)),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(
                                icon: Icons.chat_bubble_outline,
                                label: 'المحادثات',
                                value: '${convsDocs.length}',
                                context: context)),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── الإشعارات والشكاوي ──────────
                        _SectionLabel('الإجراءات', context),
                        const SizedBox(height: 10),
                        _AdminTile(
                          icon: Icons.notifications_outlined,
                          label: 'إرسال إشعار لجميع المستخدمين',
                          onTap: () => _sendNotification(context),
                          context: context,
                        ),
                        const SizedBox(height: 10),
                        _AdminTile(
                          icon: Icons.flag_outlined,
                          label: 'الشكاوي',
                          badge: pendingComplaints,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ComplaintsScreen())),
                          context: context,
                        ),

                        const SizedBox(height: 28),

                        // ── المستخدمون ──────────────────
                        _SectionLabel('المستخدمون (${usersDocs.length})', context),
                        const SizedBox(height: 10),
                        ...usersDocs.map((doc) {
                          final data       = doc.data() as Map<String, dynamic>;
                          final isDisabled = data['isDisabled'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? Colors.red.withValues(alpha: 0.06)
                                  : _card(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDisabled
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : _border(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDisabled
                                        ? Colors.red.withValues(alpha: 0.12)
                                        : _accent(context).withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    isDisabled ? Icons.lock_outline : Icons.person_outline,
                                    color: isDisabled ? Colors.red : _accent(context),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['email'] ?? '',
                                          style: appFont(color: _textMain(context),
                                              fontSize: 13, fontWeight: FontWeight.w600),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Row(
                                        children: [
                                          Text('${convCountByUser[doc.id] ?? 0} محادثة',
                                              style: appFont(color: _textMute(context), fontSize: 11)),
                                          if (isDisabled) ...[
                                            const SizedBox(width: 6),
                                            Text('• موقوف',
                                                style: appFont(color: Colors.red, fontSize: 11,
                                                    fontWeight: FontWeight.w600)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isDisabled ? Icons.lock_open_outlined : Icons.lock_outline,
                                    color: isDisabled ? Colors.green : Colors.orange,
                                    size: 20,
                                  ),
                                  onPressed: () => _toggleLock(doc.id, isDisabled),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BuildContext context;

  const _StatCard({required this.icon, required this.label, required this.value, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent(context), size: 24),
          const SizedBox(height: 10),
          Text(value,
              style: appFont(color: _textMain(context), fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: appFont(color: _textMute(context), fontSize: 12)),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final BuildContext context;
  final int badge;

  const _AdminTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.context,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Expanded(child: Text(label,
                style: appFont(color: _textMain(context), fontSize: 14, fontWeight: FontWeight.w600))),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$badge',
                    style: appFont(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, color: _textMute(context), size: 14),
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
