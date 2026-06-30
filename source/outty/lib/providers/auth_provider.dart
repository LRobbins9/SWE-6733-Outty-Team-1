import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Handles registration, login, and session persistence.
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Session ────────────────────────────────────────────────────────────────

  /// Called once at startup to restore a persisted session.
  Future<void> tryRestoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('current_user');
      if (raw != null) {
        _currentUser =
            UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      _currentUser = null;
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
    _clearError();
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    // Basic validation
    if (email.isEmpty || !email.contains('@')) {
      return _fail('Please enter a valid email address.');
    }
    if (password.length < 6) {
      return _fail('Password must be at least 6 characters.');
    }
    if (name.trim().isEmpty) {
      return _fail('Please enter your name.');
    }

    // Check for duplicate email in persisted store
    final prefs = await SharedPreferences.getInstance();
    final existingRaw = prefs.getString('user_${email.toLowerCase()}');
    if (existingRaw != null) {
      return _fail('An account with that email already exists.');
    }

    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      age: 0, // Completed in ProfileSetupScreen
      bio: '',
      email: email.toLowerCase(),
      adventureTypes: [],
      skillLevel: 'Beginner',
    );

    await _persistUser(newUser, prefs);
    _currentUser = newUser;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    if (email.isEmpty || password.isEmpty) {
      return _fail('Email and password cannot be empty.');
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_${email.toLowerCase()}');
    if (raw == null) {
      return _fail('No account found for that email.');
    }

    // MVP: passwords are not actually verified — in production use bcrypt/hash
    _currentUser =
        UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ── Update profile ─────────────────────────────────────────────────────────

  Future<void> updateCurrentUser(UserModel updated) async {
    _currentUser = updated;
    final prefs = await SharedPreferences.getInstance();
    await _persistUser(updated, prefs);
    notifyListeners();
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    _currentUser = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _persistUser(UserModel user, SharedPreferences prefs) async {
    final encoded = jsonEncode(user.toJson());
    await prefs.setString('user_${user.email}', encoded);
    await prefs.setString('current_user', encoded);
  }

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
