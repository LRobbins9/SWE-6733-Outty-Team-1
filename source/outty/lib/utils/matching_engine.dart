import '../models/user_model.dart';
import 'constants.dart';

/// Computes a compatibility score [0.0 – 1.0] between two users.
///
/// Breakdown:
///   50 % – shared adventure types
///   30 % – skill-level proximity
///   20 % – fixed "distance" factor (always 1.0 for MVP)
double computeCompatibilityScore(UserModel a, UserModel b) {
  final adventureScore = _adventureScore(a.adventureTypes, b.adventureTypes);
  final skillScore = _skillScore(a.skillLevel, b.skillLevel);
  const distanceScore = 1.0;
  return adventureScore * 0.5 + skillScore * 0.3 + distanceScore * 0.2;
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
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return scored.map((s) => s.user).toList();
}

class _ScoredUser {
  final UserModel user;
  final double score;
  _ScoredUser(this.user, this.score);
}
