import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_font.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/answer_response.dart';
import '../widgets/hadith_source_card.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

const _accent = Color(0xFFC4A882);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  Color _bg       = const Color(0xFFFAF8F5);
  Color _card     = const Color(0xFFEDE8E0);
  Color _border   = const Color(0xFFD4C9BC);
  Color _textMain = const Color(0xFF3D2B1F);
  Color _textMute = const Color(0xFF8B7355);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = Theme.of(context);
    final dark = t.brightness == Brightness.dark;
    _bg       = t.scaffoldBackgroundColor;
    _card     = t.cardColor;
    _border   = t.dividerColor;
    _textMain = t.colorScheme.onSurface;
    _textMute = dark ? const Color(0xFF9E8468) : const Color(0xFF8B7355);
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) return;
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      await _speech.listen(
        onResult: (result) {
          setState(() => _controller.text = result.recognizedWords);
        },
        localeId: 'ar_SA',
      );
      setState(() => _isListening = true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatProvider>().sendQuestion(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: false,
        drawer: _buildDrawer(),
        appBar: _buildAppBar(),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(child: _buildMessageList()),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer (محادثات سابقة) ──────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _card,
      child: SafeArea(
        child: Column(
          children: [

            // ── الشعار + اسم التطبيق ────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Image.asset(
                'assets/logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),

            // ── محادثة جديدة ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: GestureDetector(
                onTap: () {
                  context.read<ChatProvider>().newConversation();
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: _accent, size: 18),
                      const SizedBox(width: 8),
                      Text('محادثة جديدة',
                          style: appFont(
                            color: _accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // ── قائمة المحادثات ──────────────────
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  final convs = provider.sortedConversations;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    itemCount: convs.length,
                    itemBuilder: (context, index) {
                      final conv = convs[index];
                      final isCurrent = conv.id == provider.currentConversation.id;
                      return GestureDetector(
                        onTap: () {
                          provider.switchConversation(conv.id);
                          Navigator.pop(context);
                        },
                        onLongPress: () => _showConvOptions(context, provider, conv),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCurrent ? _accent.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isCurrent
                                ? Border.all(color: _accent.withValues(alpha: 0.35))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                conv.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
                                color: isCurrent ? _accent : _textMute,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conv.title,
                                      style: appFont(
                                        color: isCurrent ? _accent : _textMain,
                                        fontSize: 13,
                                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _formatDate(conv.createdAt),
                                      style: appFont(color: _textMute, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ── معلومات المستخدم (أسفل) ─────────
            Consumer<UserProvider>(
              builder: (context, userProv, _) {
                final user = userProv.user;
                final name = userProv.displayName;
                final isGuest = userProv.isGuest;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: _border)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Scaffold.of(context).closeDrawer();
                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (context.mounted) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accent.withValues(alpha: 0.12),
                                border: Border.all(color: _accent, width: 1.5),
                              ),
                              child: const Icon(Icons.person_outline, color: _accent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: appFont(
                                        color: _textMain, fontSize: 14, fontWeight: FontWeight.w700)),
                                Text(isGuest ? 'سجّل دخولك لحفظ محادثاتك' : user?.email ?? '',
                                    style: appFont(color: _textMute, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          if (isGuest) {
                            Navigator.pop(context);
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()));
                          } else {
                            final nav = Navigator.of(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  title: Text('تسجيل الخروج',
                                      style: appFont(fontWeight: FontWeight.w700)),
                                  content: Text('هل تريد تسجيل الخروج؟',
                                      style: appFont()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('إلغاء',
                                          style: appFont(color: _accent)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('خروج',
                                          style: appFont(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (confirm == true) {
                              await FirebaseAuth.instance.signOut();
                              nav.pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (_) => false,
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isGuest ? _accent : Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isGuest ? 'دخول' : 'خروج',
                              style: appFont(
                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      iconTheme: IconThemeData(color: _textMain),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Image.asset(
            'assets/logo.png',
            height: 70,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  String _lastConvId = '';

  void _showConvOptions(BuildContext context, ChatProvider provider, conv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(conv.title,
                  style: appFont(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              _OptionTile(
                icon: conv.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                label: conv.isPinned ? 'إلغاء التثبيت' : 'تثبيت المحادثة',
                color: _accent,
                onTap: () {
                  Navigator.pop(context);
                  provider.togglePin(conv.id);
                },
              ),
              _OptionTile(
                icon: Icons.edit_outlined,
                label: 'تغيير الاسم',
                color: Theme.of(context).colorScheme.onSurface,
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, provider, conv);
                },
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                label: 'حذف المحادثة',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  provider.deleteConversation(conv.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ChatProvider provider, conv) {
    final ctrl = TextEditingController(text: conv.title);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('تغيير الاسم',
              style: appFont(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textDirection: TextDirection.rtl,
            style: appFont(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: appFont(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  provider.renameConversation(conv.id, ctrl.text.trim());
                }
                Navigator.pop(ctx);
              },
              child: Text('حفظ', style: appFont(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'الآن';
    if (diff.inHours < 1)    return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1)     return 'منذ ${diff.inHours} س';
    if (diff.inDays == 1)    return 'أمس';
    return '${dt.day}/${dt.month}';
  }

  // ── Message list ────────────────────────────
  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final messages = provider.messages;
        final convId   = provider.currentConversationId;

        // Reset scroll position when conversation changes
        if (convId != _lastConvId) {
          _lastConvId = convId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent);
            }
          });
        }

        if (provider.isSyncing) {
          return Center(
            child: CircularProgressIndicator(
                color: _accent, strokeWidth: 2),
          );
        }

        if (messages.isEmpty && !provider.isLoading) {
          return _buildEmptyState();
        }

        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length) return _buildTypingIndicator();
            return _buildMessageBubble(messages[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final name = context.read<UserProvider>().user?.displayName?.split(' ').first ?? '';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/logo.png', height: 200, fit: BoxFit.contain),
          const SizedBox(height: 16),
          if (name.isNotEmpty)
            Text('أهلاً $name',
                style: appFont(
                    color: _textMain, fontSize: 20, fontWeight: FontWeight.w600)),
          if (name.isNotEmpty) const SizedBox(height: 8),
          Text('هُداي.. معك في تدبّرك، وفي ضيقك، وفي تساؤلاتك',
              style: appFont(
                  color: _accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('سيتم الرد بناءً على القرآن الكريم وصحيح السنة النبوية',
              style: appFont(color: _textMute, fontSize: 15),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _reportMessage(ChatMessage message) async {
    final isGuest = context.read<UserProvider>().isGuest;
    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('يجب تسجيل الدخول أولاً للإبلاغ عن رسالة',
            style: appFont(color: Colors.white)),
        backgroundColor: const Color(0xFFC4A882),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('إبلاغ عن رسالة', style: appFont(color: _textMain, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اذكر سبب الإبلاغ (اختياري)',
                  style: appFont(color: _textMute, fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 3,
                textDirection: TextDirection.rtl,
                style: appFont(color: _textMain, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'سبب الإبلاغ...',
                  hintStyle: appFont(color: _textMute, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: appFont(color: _textMute)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('إبلاغ', style: appFont(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('complaints').add({
        'messageText': message.text,
        'reason':      ctrl.text.trim(),
        'reportedBy':  FirebaseAuth.instance.currentUser?.uid ?? 'guest',
        'reportedAt':  FieldValue.serverTimestamp(),
        'isResolved':  false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم إرسال البلاغ، شكراً لك', style: appFont(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
    ctrl.dispose();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser  = message.type == MessageType.user;
    final isError = message.type == MessageType.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: (!isUser && !isError) ? () => _reportMessage(message) : null,
            child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser
                  ? _accent.withValues(alpha: 0.2)
                  : isError
                      ? const Color(0xFFFFEEEE)
                      : _card,
              borderRadius: BorderRadius.only(
                topRight: const Radius.circular(16),
                topLeft: const Radius.circular(16),
                bottomLeft: isUser
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              border: Border.all(
                color: isUser
                    ? _accent.withValues(alpha: 0.4)
                    : isError
                        ? const Color(0xFFFFCCCC)
                        : _border,
                width: 1,
              ),
            ),
            child: Text(
              message.text,
              style: appFont(
                color: isError ? const Color(0xFFCC4444) : _textMain,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          ),
          ),
          if (!isUser && !isError && message.response != null) ...[
            const SizedBox(height: 8),
            _buildMetaBar(message.response!),
            if (message.response!.sources.isNotEmpty)
              ...message.response!.sources
                  .map((s) => HadithSourceCard(source: s)),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaBar(AnswerResponse response) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _MetaChip(
              icon: Icons.search,
              label: 'الكلمة: ${response.keywordUsed}'),
          const SizedBox(width: 8),
          _MetaChip(
              icon: Icons.filter_alt_outlined,
              label:
                  '${response.totalAfterFilter}/${response.totalRetrieved} حديث'),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const _DotIndicator(delay: 0),
                const SizedBox(width: 4),
                const _DotIndicator(delay: 200),
                const SizedBox(width: 4),
                const _DotIndicator(delay: 400),
                const SizedBox(width: 8),
                Text('جاري البحث...',
                    style:
                        appFont(color: _textMute, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 16;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                style: appFont(color: _textMain, fontSize: 17),
                decoration: InputDecoration(
                  hintText: 'اكتب سؤالك...',
                  hintStyle:
                      appFont(color: _textMute, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                ),
                maxLines: 3,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? const Color(0xFFE53935)
                    : _card,
                border: Border.all(
                  color: _isListening ? const Color(0xFFE53935) : _border,
                  width: 1.5,
                ),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE53935).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none_rounded,
                color: _isListening ? Colors.white : _textMute,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<ChatProvider>(
            builder: (context, provider, _) => GestureDetector(
              onTap: provider.isLoading ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.isLoading ? _border : _accent,
                  boxShadow: provider.isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: provider.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ─── Helper Widgets ───────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bg = t.scaffoldBackgroundColor;
    final border = t.dividerColor;
    final muted = t.brightness == Brightness.dark ? const Color(0xFF9E8468) : const Color(0xFF8B7355);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: muted),
          const SizedBox(width: 4),
          Text(label, style: appFont(color: muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatefulWidget {
  final int delay;
  const _DotIndicator({required this.delay});

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _accent,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: appFont(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }
}

