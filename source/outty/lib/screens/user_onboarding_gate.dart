import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'hub_screen.dart';
import 'onboarding_screen.dart';

class UserOnboardingGate extends StatefulWidget {
  const UserOnboardingGate({super.key, required this.user});

  final User user;

  @override
  State<UserOnboardingGate> createState() => _UserOnboardingGateState();
}

class _UserOnboardingGateState extends State<UserOnboardingGate> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    // Reload auth profile so displayName is fresh after a sign-in.
    try {
      await widget.user.reload();
    } catch (_) {}
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final profileData = snapshot.data;
        // Use multiple signals: Firestore flag, Firestore name field, or Auth displayName.
        final freshUser = FirebaseAuth.instance.currentUser;
        final completedOnboarding =
            (profileData?['onboardingComplete'] == true) ||
            ((profileData?['name'] as String?)?.isNotEmpty == true) ||
            (freshUser?.displayName?.isNotEmpty == true);
        if (completedOnboarding) {
          return HubScreen(user: freshUser ?? widget.user);
        }

        return OnboardingScreen(
          user: widget.user,
          onComplete: () {
            setState(() {
              _profileFuture = _loadProfile();
            });
          },
        );
      },
    );
  }
}
