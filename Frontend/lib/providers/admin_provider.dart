import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAdmin = false;
  bool _loading = true;
  late final StreamSubscription<User?> _sub;

  bool get isAdmin  => _isAdmin;
  bool get loading  => _loading;

  AdminProvider() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _checkAdmin(user?.uid);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _checkAdmin(String? uid) async {
    if (uid == null) {
      _isAdmin = false;
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();
      _isAdmin = doc.exists;
    } catch (_) {
      _isAdmin = false;
    }
    _loading = false;
    notifyListeners();
  }
}
