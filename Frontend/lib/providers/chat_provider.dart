import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/answer_response.dart';
import '../services/api_service.dart';

class Conversation {
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  bool isPinned;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
    'messages': messages.map((m) => m.toMap()).toList(),
  };

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      title: data['title'] ?? 'محادثة جديدة',
      messages: (data['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Conversation empty() => Conversation(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'محادثة جديدة',
    messages: [],
    createdAt: DateTime.now(),
  );
}

class ChatProvider extends ChangeNotifier {
  final List<Conversation> _conversations = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _uid;
  late final StreamSubscription<User?> _authSub;

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  bool get isLoading  => _isLoading;
  bool get isSyncing  => _isSyncing;

  Conversation get currentConversation {
    if (_conversations.isEmpty) {
      final c = Conversation.empty();
      _conversations.add(c);
      _currentIndex = 0;
    }
    return _conversations[_currentIndex];
  }

  String get currentConversationId => currentConversation.id;
  List<ChatMessage> get messages => List.unmodifiable(currentConversation.messages);

  CollectionReference? get _col {
    if (_uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('conversations');
  }

  ChatProvider() {
    // Start with the cached local user — no async delay
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadConversations();
    // Only reload when the user actually changes (login / logout)
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final newUid = user?.uid;
      if (newUid != _uid) {
        _uid = newUid;
        _loadConversations();
      }
    });
  }

  Future<void> _loadConversations() async {
    _isSyncing = true;
    _conversations.clear();
    _currentIndex = 0;
    notifyListeners();

    if (_uid == null) {
      _isSyncing = false;
      notifyListeners();
      return;
    }

    try {
      final snap = await _col!
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in snap.docs) {
        _conversations.add(Conversation.fromFirestore(doc));
      }
    } catch (_) {}


    _isSyncing = false;
    notifyListeners();
  }

  Future<void> _save(Conversation conv) async {
    if (_uid == null) return;
    try {
      await _col!.doc(conv.id).set(conv.toMap());
    } catch (_) {}
  }

  void newConversation() {
    if (currentConversation.messages.isEmpty) {
      notifyListeners();
      return;
    }
    final conv = Conversation.empty();
    _conversations.insert(0, conv);
    _currentIndex = 0;
    notifyListeners();
    _save(conv);
  }

  void switchConversation(String id) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> sendQuestion(String question) async {
    if (question.trim().isEmpty) return;

    final conv = currentConversation;
    if (conv.messages.isEmpty) {
      conv.title = question.length > 35
          ? '${question.substring(0, 35)}...'
          : question;
    }

    conv.messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: question,
      type: MessageType.user,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final history = conv.messages
          .where((m) => m.type == MessageType.user || m.type == MessageType.assistant)
          .take(10)
          .map((m) => {
                'role': m.type == MessageType.user ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final response = await ApiService.ask(question, history: history);
      conv.messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ans',
        text: response.answer,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        response: response,
      ));
    } catch (e) {
      conv.messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_err',
        text: 'حدث خطأ: ${e.toString()}',
        type: MessageType.error,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
      _save(conv);
    }
  }

  List<Conversation> get sortedConversations {
    return [..._conversations]..sort((a, b) {
      if (a.isPinned == b.isPinned) return 0;
      return a.isPinned ? -1 : 1;
    });
  }

  void togglePin(String id) {
    final conv = _conversations.firstWhere((c) => c.id == id);
    conv.isPinned = !conv.isPinned;
    notifyListeners();
    _save(conv);
  }

  void renameConversation(String id, String newTitle) {
    final conv = _conversations.firstWhere((c) => c.id == id);
    conv.title = newTitle;
    notifyListeners();
    _save(conv);
  }

  void deleteConversation(String id) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _conversations.removeAt(index);
    if (_conversations.isEmpty) {
      _conversations.add(Conversation.empty());
      _currentIndex = 0;
    } else {
      _currentIndex = (_currentIndex >= _conversations.length)
          ? _conversations.length - 1
          : _currentIndex;
    }
    notifyListeners();
    if (_uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('conversations')
          .doc(id)
          .delete()
          .catchError((_) {});
    }
  }

  void clearChat() {
    final conv = currentConversation;
    conv.messages.clear();
    conv.title = 'محادثة جديدة';
    notifyListeners();
    _save(conv);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
