import 'package:flutter/material.dart';

// ─── Brand colors ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF05A22); // Vibrant Orange
  static const Color primaryLight = Color(0xFFFF8A50);
  static const Color secondary = Color(0xFF2D6A4F); // Forest green as secondary
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color like = Color(0xFF4CAF50);
  static const Color pass = Color(0xFFF44336);
  static const Color overlay = Color(0x80000000);
  static const Color messageSent = Color(0xFFF05A22);
  static const Color messageReceived = Color(0xFFE0E0E0);
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
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String chat = '/chat';
}
