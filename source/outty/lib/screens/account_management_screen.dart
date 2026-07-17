import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/centered_content.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({
    super.key,
    required this.user,
    this.profileData,
  });

  final User user;
  final Map<String, dynamic>? profileData;

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _deletePasswordController = TextEditingController();
  String _initialName = '';
  bool _isSaving = false;
  bool _isDeleting = false;

    bool get _usesPasswordSignIn =>
      widget.user.providerData.any((p) => p.providerId == 'password');

    bool get _usesGoogleSignIn =>
      widget.user.providerData.any((p) => p.providerId == 'google.com');

  @override
  void initState() {
    super.initState();
    _initialName = (widget.profileData?['name'] as String?) ?? '';
    _displayNameController.text = _initialName;
    _emailController.text = widget.user.email ?? '';

    if (_initialName.isEmpty) {
      _loadNameFromProfile();
    }
  }

  Future<void> _loadNameFromProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      final name = (doc.data()?['name'] as String?)?.trim();
      if (!mounted || name == null || name.isEmpty) {
        return;
      }

      setState(() {
        _initialName = name;
        _displayNameController.text = name;
      });
    } catch (_) {
      // Keep the field editable even if profile lookup fails.
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    setState(() => _isSaving = true);

    try {
      final user = widget.user;
      final changes = <Future<void>>[];
      final canChangeCredentials = _usesPasswordSignIn;

      final trimmedName = _displayNameController.text.trim();
      if (trimmedName != _initialName) {
        // Keep Firebase Auth profile in sync, but Firestore `name` is source of truth.
        changes.add(user.updateDisplayName(trimmedName));
      }

      if (canChangeCredentials &&
          _emailController.text.trim() != (user.email ?? '')) {
        if (_currentPasswordController.text.isEmpty) {
          throw FirebaseAuthException(
            code: 'reauth-required',
            message: 'Enter your current password before changing your email.',
          );
        }
        final credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      if (canChangeCredentials && _passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw FirebaseAuthException(
            code: 'password-mismatch',
            message: 'New passwords do not match.',
          );
        }
        if (_currentPasswordController.text.isEmpty) {
          throw FirebaseAuthException(
            code: 'reauth-required',
            message:
                'Enter your current password before changing your password.',
          );
        }
        final credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        changes.add(user.updatePassword(_passwordController.text));
      }

      if (!canChangeCredentials &&
          ((_emailController.text.trim() != (user.email ?? '')) ||
              _passwordController.text.isNotEmpty ||
              _confirmPasswordController.text.isNotEmpty ||
              _currentPasswordController.text.isNotEmpty)) {
        throw FirebaseAuthException(
          code: 'unsupported-provider-action',
          message:
              'Email and password changes are not available for Google sign-in accounts.',
        );
      }

      await Future.wait(changes);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': trimmedName,
        'email': canChangeCredentials
            ? _emailController.text.trim()
            : (user.email ?? '').trim(),
        'onboardingComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _initialName = trimmedName;

      if (!mounted) return;
      _showMessage('Account updated successfully.');
      _passwordController.clear();
      _confirmPasswordController.clear();
      _currentPasswordController.clear();
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Unable to update account.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_usesPasswordSignIn && _deletePasswordController.text.isEmpty) {
      _showMessage('Enter your password to delete your account.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently remove your account and profile data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final user = widget.user;
      if (_usesPasswordSignIn) {
        final credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: _deletePasswordController.text,
        );
        await user
            .reauthenticateWithCredential(credential)
            .timeout(const Duration(seconds: 12));
      } else if (_usesGoogleSignIn) {
        // Web supports popup reauth for OAuth providers. Some platforms throw
        // unimplemented for reauthenticateWithProvider with Google.
        if (kIsWeb) {
          final provider = GoogleAuthProvider();
          provider.setCustomParameters({'prompt': 'select_account'});
          await user
              .reauthenticateWithPopup(provider)
              .timeout(const Duration(seconds: 20));
        } else {
          await user
              .reauthenticateWithProvider(GoogleAuthProvider())
              .timeout(const Duration(seconds: 20));
        }
      }

      await context
          .read<AuthProvider>()
          .deleteProfilePhotosForUser(user.uid)
          .timeout(const Duration(seconds: 8));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete()
          .timeout(const Duration(seconds: 12));
      await user.delete().timeout(const Duration(seconds: 12));

      if (!mounted) return;
      _showMessage('Account deleted.');
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Unable to delete account.');
    } on TimeoutException {
      _showMessage('Delete request timed out. Please try again.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage account'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: CenteredContent(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signed in as',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email ?? 'No email',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(labelText: 'name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        readOnly: !_usesPasswordSignIn,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (_usesPasswordSignIn) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText:
                                'Current password (required for changes)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'New password',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm new password',
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Text(
                          'Email and password are managed by your Google account.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveAccount,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save changes'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete account',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This permanently removes your Outty account and all profile data.',
                      ),
                      if (_usesPasswordSignIn) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _deletePasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password to confirm deletion',
                          ),
                        ),
                      ] else if (_usesGoogleSignIn) ...[
                        const SizedBox(height: 12),
                        Text(
                          'You will confirm deletion with your Google account.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isDeleting ? null : _deleteAccount,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_forever),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        label: const Text('Delete account'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
