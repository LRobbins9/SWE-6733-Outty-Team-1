import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

/// Handles registration, login, and session persistence using Firebase.
class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;
  FirebaseStorage? _storage;
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _initAuthListener();
  }

  bool _ensureFirebaseReady() {
    if (_auth != null && _db != null && _storage != null) return true;
    try {
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
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
      debugPrint('Error fetching user profile: $e');
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

  Future<bool> login({required String email, required String password}) async {
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
      debugPrint('Error updating profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> uploadProfilePhoto() async {
    if (!_ensureFirebaseReady()) {
      _errorMessage = 'Firebase is not initialized.';
      notifyListeners();
      return null;
    }

    final user = _currentUser;
    if (user == null) {
      _errorMessage = 'No signed-in user is available.';
      notifyListeners();
      return null;
    }

    _clearError();

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 70,
      );

      if (pickedFile == null) {
        return null;
      }

      _isLoading = true;
      notifyListeners();

      final bytes = await pickedFile.readAsBytes();
      final photoRef = _storage!.ref().child(
        'profile_pictures/${user.id}/profile_photo',
      );

      await photoRef.putData(
        bytes,
        SettableMetadata(
          contentType: pickedFile.mimeType ?? 'image/jpeg',
          cacheControl: 'public,max-age=3600',
        ),
      );

      final photoUrl = await photoRef.getDownloadURL();
      await _db!.collection('users').doc(user.id).update({
        'photoUrl': photoUrl,
      });
      _currentUser = user.copyWith(photoUrl: photoUrl);
      return photoUrl;
    } on PlatformException catch (e) {
      debugPrint('Image picker error: ${e.code} ${e.message}');
      _errorMessage = e.message ?? 'Unable to select a photo.';
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Firebase photo upload error: ${e.code} ${e.message}');
      _errorMessage = e.message ?? 'Unable to upload photo.';
      return null;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      _errorMessage = 'Unable to upload photo.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProfilePhotosForUser(String uid) async {
    if (!_ensureFirebaseReady()) {
      return;
    }

    try {
      final folderRef = _storage!.ref().child('profile_pictures/$uid');
      final result = await folderRef.listAll();

      await Future.wait(
        result.items.map((item) async {
          try {
            await item.delete();
          } on FirebaseException catch (error) {
            if (error.code != 'object-not-found') {
              rethrow;
            }
          }
        }),
      );
    } catch (e) {
      debugPrint('Error deleting profile photos for $uid: $e');
      rethrow;
    }
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
