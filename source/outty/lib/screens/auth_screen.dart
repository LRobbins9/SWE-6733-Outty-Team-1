import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw FirebaseAuthException(
            code: 'password-mismatch',
            message: 'Passwords do not match.',
          );
        }

        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        final displayName = _emailController.text.trim().split('@').first;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'uid': credential.user!.uid,
              'email': credential.user!.email,
              'displayName': displayName,
              'onboardingComplete': false,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Authentication failed.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
      body: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2F4F4F),
                    const Color(0xFF4CAF50).withValues(alpha: 0.8),
                    const Color(0xFF1E88E5).withValues(alpha: 0.7),
                  ],
                ),
                image: DecorationImage(
                  image: const NetworkImage(
                    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1200&q=80',
                  ),
                  fit: BoxFit.cover,
                  onError: (_, _) {},
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF11181C).withValues(alpha: 0.45),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                    const Icon(Icons.explore, size: 56, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'OUTTY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find Your Adventure Partner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                        minWidth: 300,
                      ),
                      child: Card(
                        color: const Color(0xFF1B2A2A),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Account Information',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isLogin
                                      ? 'Sign in to Outty'
                                      : 'Create account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Please enter your email.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password.';
                                    }
                                    if (!_isLogin && value.length < 6) {
                                      return 'Password must be at least 6 characters.';
                                    }
                                    return null;
                                  },
                                ),
                                if (!_isLogin) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm password',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: _isSubmitting ? null : _submit,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.lock_open),
                                  label: Text(
                                    _isLogin
                                        ? 'Sign in'
                                        : 'Create account',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? 'Create account'
                                        : 'Already have an account?',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    ],
    ),
    );
  }
}
