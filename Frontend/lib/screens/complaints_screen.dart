import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_font.dart';

Color _accent(BuildContext ctx)   => Theme.of(ctx).colorScheme.primary;
Color _bg(BuildContext ctx)       => Theme.of(ctx).scaffoldBackgroundColor;
Color _card(BuildContext ctx)     => Theme.of(ctx).cardColor;
Color _border(BuildContext ctx)   => Theme.of(ctx).dividerColor;
Color _textMain(BuildContext ctx) => Theme.of(ctx).colorScheme.onSurface;
Color _textMute(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF9E8468)
    : const Color(0xFF8B7355);

class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  Future<void> _toggleResolved(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(id)
        .update({'isResolved': !current});
  }

  Future<void> _delete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _card(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('حذف الشكوى', style: appFont(color: Colors.red, fontWeight: FontWeight.w700)),
          content: Text('هل تريد حذف هذه الشكوى؟', style: appFont(color: _textMain(context))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: appFont(color: _textMute(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حذف', style: appFont(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('complaints').doc(id).delete();
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
        title: Text('الشكاوي',
            style: appFont(color: _textMain(context), fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textMain(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('complaints')
              .orderBy('reportedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _accent(context)));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, color: _textMute(context), size: 56),
                    const SizedBox(height: 12),
                    Text('لا توجد شكاوي', style: appFont(color: _textMute(context), fontSize: 15)),
                  ],
                ),
              );
            }

            final pending  = docs.where((d) => (d.data() as Map)['isResolved'] != true).toList();
            final resolved = docs.where((d) => (d.data() as Map)['isResolved'] == true).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (pending.isNotEmpty) ...[
                  _label('معلقة (${pending.length})', context),
                  const SizedBox(height: 10),
                  ...pending.map((doc) => _ComplaintCard(
                    id: doc.id,
                    data: doc.data() as Map<String, dynamic>,
                    onToggle: () => _toggleResolved(doc.id, false),
                    onDelete: () => _delete(context, doc.id),
                    context: context,
                  )),
                  const SizedBox(height: 24),
                ],
                if (resolved.isNotEmpty) ...[
                  _label('تم الحل (${resolved.length})', context),
                  const SizedBox(height: 10),
                  ...resolved.map((doc) => _ComplaintCard(
                    id: doc.id,
                    data: doc.data() as Map<String, dynamic>,
                    onToggle: () => _toggleResolved(doc.id, true),
                    onDelete: () => _delete(context, doc.id),
                    context: context,
                  )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(String text, BuildContext context) {
    return Text(text,
        style: appFont(color: _textMute(context), fontSize: 13, fontWeight: FontWeight.w600));
  }
}

class _ComplaintCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final BuildContext context;

  const _ComplaintCard({
    required this.id,
    required this.data,
    required this.onToggle,
    required this.onDelete,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final isResolved  = data['isResolved'] == true;
    final messageText = data['messageText'] as String? ?? '';
    final reason      = data['reason'] as String? ?? '';
    final reportedAt  = (data['reportedAt'] as Timestamp?)?.toDate();
    final dateStr     = reportedAt != null
        ? '${reportedAt.day}/${reportedAt.month}/${reportedAt.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isResolved
            ? Colors.green.withValues(alpha: 0.05)
            : _card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isResolved
              ? Colors.green.withValues(alpha: 0.3)
              : _border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Icon(
                  isResolved ? Icons.check_circle_outline : Icons.report_outlined,
                  color: isResolved ? Colors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(dateStr,
                      style: appFont(color: _textMute(context), fontSize: 11)),
                ),
                IconButton(
                  icon: Icon(
                    isResolved ? Icons.refresh : Icons.check,
                    color: isResolved ? _textMute(context) : Colors.green,
                    size: 18,
                  ),
                  tooltip: isResolved ? 'إعادة فتح' : 'تم الحل',
                  onPressed: onToggle,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),

          // نص الرسالة المُبلَّغ عنها
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bg(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border(context)),
              ),
              child: Text(
                messageText,
                style: appFont(color: _textMain(context), fontSize: 13, height: 1.6),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // سبب الإبلاغ
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('السبب: ', style: appFont(color: _textMute(context), fontSize: 12, fontWeight: FontWeight.w600)),
                  Expanded(child: Text(reason, style: appFont(color: _textMain(context), fontSize: 12))),
                ],
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
