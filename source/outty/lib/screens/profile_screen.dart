import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'account_management_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../utils/constants.dart';
import '../widgets/centered_content.dart';
import '../widgets/adventure_chip.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final matchCount = context.watch<MatchProvider>().matches.length;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final hue = (user.name.codeUnitAt(0) * 37) % 360;
    final color1 =
        HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.35).toColor();
    final color2 =
        HSLColor.fromAHSL(1, (hue + 40) % 360, 0.5, 0.45).toColor();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSetupScreen(isEditing: true),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                user.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color1, color2],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            Colors.white.withAlpha(80),
                        child: Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: CenteredContent(
              maxWidth: 760,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _StatCard(
                          label: 'Matches',
                          value: '$matchCount',
                          icon: Icons.favorite,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Adventures',
                          value: '${user.adventureTypes.length}',
                          icon: Icons.terrain,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Skill',
                          value: user.skillLevel,
                          icon: Icons.bar_chart,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Identity Info
                  if (user.gender != null || user.interestedIn != null)
                    _InfoSection(
                      title: 'Details',
                      child: Row(
                        children: [
                          if (user.gender != null)
                            Expanded(child: _DetailChip(label: 'Identity', value: user.gender!, icon: Icons.person)),
                          if (user.interestedIn != null)
                            Expanded(child: _DetailChip(label: 'Seeking', value: user.interestedIn!, icon: Icons.favorite)),
                        ],
                      ),
                    ),

                  _InfoSection(
                    title: 'About',
                    child: Text(
                      user.bio.isEmpty ? 'No bio yet. Tap Edit Profile to add one.' : user.bio,
                      style: TextStyle(
                        color: user.bio.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontStyle: user.bio.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),

                  if (user.location != null)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(user.location!,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14)),
                        ],
                      ),
                    ),

                  if (user.instagramHandle != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.camera_alt_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('@${user.instagramHandle}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  _InfoSection(
                    title: 'Adventure Types',
                    child: user.adventureTypes.isEmpty
                        ? Text(
                            'None selected yet.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 13),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.adventureTypes
                                .map((a) => AdventureChip(
                                      label: a,
                                      selected: true,
                                    ))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.edit,
                          label: 'Edit Profile',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileSetupScreen(isEditing: true),
                            ),
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.delete_forever,
                          label: 'Manage Account',
                          onTap: () => _openAccountManagement(context),
                          isDestructive: true,
                        ),
                        _SettingsTile(
                          icon: Icons.logout,
                          label: 'Log Out',
                          onTap: () => _confirmLogout(context),
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                ),
              ),
          ),
        ],
      ),
    );
  }

  void _openAccountManagement(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No signed-in account is available.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountManagementScreen(user: firebaseUser),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (_) => false);
              }
            },
            child: const Text('Log Out',
                style: TextStyle(color: AppColors.pass)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.pass : AppColors.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
