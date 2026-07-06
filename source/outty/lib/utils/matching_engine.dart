import '../models/user_model.dart';
import 'constants.dart';

/// Computes a compatibility score [0.0 – 1.0] between two users.
///
/// Breakdown:
///   50 % – shared adventure types
///   30 % – skill-level proximity
///   20 % – fixed "distance" factor (always 1.0 for MVP1)
double computeCompatibilityScore(UserModel a, UserModel b) {
  // Check gender and age preferences first
  if (!_checkPreference(a, b) || !_checkPreference(b, a)) {
    return 0.0;
  }

  final adventureScore = _adventureScore(a.adventureTypes, b.adventureTypes);
  final skillScore = _skillScore(a.skillLevel, b.skillLevel);
  const distanceScore = 1.0; // this would require an api call to compute distance, so we just use a fixed value for MVP1
  return adventureScore * 0.5 + skillScore * 0.3 + distanceScore * 0.2;
}

bool _checkPreference(UserModel seeker, UserModel candidate) {
  // Only return candidates that match age restrictions.
  if (seeker.targetAgeStart != null && seeker.targetAgeEnd != null) {
    final age = candidate.age;
    if (age < seeker.targetAgeStart! ||
        age > seeker.targetAgeEnd!) {
      return false;
    }
  }

  // keep checking if an exclusion hasn't been found yet

  if (candidate.targetAgeStart != null && candidate.targetAgeEnd != null) {
    final age = seeker.age;
    if (age < candidate.targetAgeStart! ||
        age > candidate.targetAgeEnd!) {
      return false;
    }
  }

  // keep checking if an exclusion hasn't been found yet

  // If preference is not set (legacy/null), assume "Any"
  if (seeker.interestedIn == null || seeker.interestedIn == 'Any') {
    return true;
  }
  // If candidate gender is not set, we can't be sure, so allow it for MVP1
  if (candidate.gender == null) {
    return true;
  }
  return seeker.interestedIn == candidate.gender;
}

double _adventureScore(List<String> a, List<String> b) {
  if (a.isEmpty && b.isEmpty) return 0.5;
  final setA = a.toSet();
  final shared = b.where(setA.contains).length;
  final total = {...a, ...b}.length;
  return total == 0 ? 0 : shared / total;
}

double _skillScore(String a, String b) {
  final indexA = kSkillLevels.indexOf(a);
  final indexB = kSkillLevels.indexOf(b);
  if (indexA < 0 || indexB < 0) return 0.5;
  final diff = (indexA - indexB).abs();
  switch (diff) {
    case 0:
      return 1.0;
    case 1:
      return 0.75;
    case 2:
      return 0.5;
    default:
      return 0.25;
  }
}

/// Returns [candidates] sorted by descending compatibility with [user].
List<UserModel> rankCandidates(UserModel user, List<UserModel> candidates) {
  final scored = candidates.map((c) {
    return _ScoredUser(c, computeCompatibilityScore(user, c));
  }).where((s) => s.score > 0).toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return scored.map((s) => s.user).toList();
}

class _ScoredUser {
  final UserModel user;
  final double score;
  _ScoredUser(this.user, this.score);
}
