import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles registration, login, and session persistence using Firebase.
class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _initAuthListener();
  }

  bool _ensureFirebaseReady() {
    if (_auth != null && _db != null) return true;
    try {
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Session ────────────────────────────────────────────────────────────────

  void _initAuthListener() {
    if (!_ensureFirebaseReady()) {
      return;
    }

    _auth!.authStateChanges().listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        notifyListeners();
      } else {
        await _fetchUserProfile(user.uid);
      }
    });
  }

  /// Manually trigger a check/refresh of the current user's profile.
  Future<void> tryRestoreSession() async {
    if (!_ensureFirebaseReady()) {
      return;
    }

    final user = _auth!.currentUser;
    if (user != null) {
      await _fetchUserProfile(user.uid);
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    if (!_ensureFirebaseReady()) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _db!.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    if (!_ensureFirebaseReady()) {
      return _fail('Firebase is not initialized.');
    }

    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Create user in Firebase Auth
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Create profile in Firestore
      final newUser = UserModel(
        id: uid,
        name: name.trim(),
        age: 0,
        bio: '',
        email: email.trim().toLowerCase(),
        adventureTypes: [],
        skillLevel: 'Beginner',
      );

      await _db!.collection('users').doc(uid).set(newUser.toJson());
      _currentUser = newUser;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      return _fail(e.message ?? 'An error occurred during registration.');
    } catch (e) {
      return _fail('An unexpected error occurred.');
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (!_ensureFirebaseReady()) {
      return _fail('Firebase is not initialized.');
    }

    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      await _fetchUserProfile(credential.user!.uid);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      return _fail(e.message ?? 'Invalid email or password.');
    } catch (e) {
      return _fail('An unexpected error occurred.');
    }
  }

  // ── Update profile ─────────────────────────────────────────────────────────

  Future<void> updateCurrentUser(UserModel updated) async {
    if (!_ensureFirebaseReady()) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _db!.collection('users').doc(updated.id).update(updated.toJson());
      _currentUser = updated;
    } catch (e) {
      print('Error updating profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    if (!_ensureFirebaseReady()) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    await _auth!.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _fail(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
