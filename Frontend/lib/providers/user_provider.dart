import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  late final StreamSubscription<User?> _sub;

  User? get user    => _user;
  bool  get isGuest => _user == null;
  String get displayName {
    final name = _user?.displayName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return 'مستخدم';
  }

  UserProvider() {
    // Initialize immediately from local cache (no async wait)
    _user = FirebaseAuth.instance.currentUser;
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _user?.uid) {
        _user = user;
        notifyListeners();
      }
    });
  }

  Future<void> reload() async {
    await FirebaseAuth.instance.currentUser?.reload();
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
