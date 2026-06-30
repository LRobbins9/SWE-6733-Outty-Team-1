import 'package:flutter/material.dart';

// ─── Brand colors ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2D6A4F); // Forest green
  static const Color primaryLight = Color(0xFF52B788);
  static const Color secondary = Color(0xFFF4A261); // Earth orange
  static const Color background = Color(0xFFF0F4F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B2432);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color like = Color(0xFF40C057);
  static const Color pass = Color(0xFFFF6B6B);
  static const Color overlay = Color(0x80000000);
  static const Color messageSent = Color(0xFF52B788);
  static const Color messageReceived = Color(0xFFE9ECEF);
}

// ─── Adventure types ─────────────────────────────────────────────────────────
const List<String> kAdventureTypes = [
  'Hiking',
  'Backpacking',
  'Rock Climbing',
  'Bouldering',
  'Kayaking',
  'White Water Rafting',
  'Camping',
  'Skiing',
  'Snowboarding',
  'Mountain Biking',
  'Cycling',
  'Trail Running',
  'Surfing',
  'Scuba Diving',
  'Traveling',
];

const List<String> kSkillLevels = [
  'Beginner',
  'Intermediate',
  'Advanced',
  'Expert',
];

// ─── Route names ─────────────────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String chat = '/chat';
}
