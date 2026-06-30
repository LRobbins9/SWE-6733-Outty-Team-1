import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../utils/constants.dart';
import '../widgets/adventure_chip.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();

  int _age = 25;
  String _skillLevel = kSkillLevels.first;
  int _maxDistance = 50;
  final Set<String> _selectedAdventures = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate from existing profile if editing
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _bioCtrl.text = user.bio;
      _locationCtrl.text = user.location ?? '';
      _instagramCtrl.text = user.instagramHandle ?? '';
      _age = user.age > 0 ? user.age : 25;
      _skillLevel = user.skillLevel;
      _maxDistance = user.maxDistance;
      _selectedAdventures.addAll(user.adventureTypes);
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedAdventures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one adventure type.'),
          backgroundColor: AppColors.pass,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final updated = auth.currentUser!.copyWith(
      age: _age,
      bio: _bioCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      instagramHandle: _instagramCtrl.text.trim().isEmpty
          ? null
          : _instagramCtrl.text.trim(),
      adventureTypes: _selectedAdventures.toList(),
      skillLevel: _skillLevel,
      maxDistance: _maxDistance,
    );

    await auth.updateCurrentUser(updated);

    if (!mounted) return;
    await context.read<MatchProvider>().load(updated);

    setState(() => _saving = false);
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Up Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(title: 'About You', icon: Icons.person),
            const SizedBox(height: 12),

            // Age slider
            _labelRow('Age', '$_age'),
            Slider(
              value: _age.toDouble(),
              min: 18,
              max: 75,
              divisions: 57,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _age = v.toInt()),
            ),
            const SizedBox(height: 12),

            // Bio
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: _inputDecoration('Bio', Icons.edit_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Add a short bio';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Location
            TextFormField(
              controller: _locationCtrl,
              decoration:
                  _inputDecoration('Location (e.g. Denver, CO)', Icons.location_on_outlined),
            ),
            const SizedBox(height: 12),

            // Instagram
            TextFormField(
              controller: _instagramCtrl,
              decoration: _inputDecoration(
                  'Instagram handle (optional)', Icons.camera_alt_outlined),
            ),

            const SizedBox(height: 24),
            _SectionHeader(title: 'Adventure Preferences', icon: Icons.terrain),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kAdventureTypes.map((a) {
                final sel = _selectedAdventures.contains(a);
                return AdventureChip(
                  label: a,
                  selected: sel,
                  onTap: () {
                    setState(() {
                      if (sel) {
                        _selectedAdventures.remove(a);
                      } else {
                        _selectedAdventures.add(a);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            _SectionHeader(title: 'Skill Level', icon: Icons.bar_chart),
            const SizedBox(height: 12),
            ...kSkillLevels.map((level) {
              return RadioListTile<String>(
                value: level,
                groupValue: _skillLevel,
                activeColor: AppColors.primary,
                title: Text(level),
                onChanged: (v) => setState(() => _skillLevel = v!),
                contentPadding: EdgeInsets.zero,
              );
            }),

            const SizedBox(height: 16),
            _SectionHeader(
                title: 'Max Distance', icon: Icons.social_distance),
            _labelRow('Search radius', '$_maxDistance mi'),
            Slider(
              value: _maxDistance.toDouble(),
              min: 10,
              max: 500,
              divisions: 49,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _maxDistance = v.toInt()),
            ),

            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save & Start Exploring',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE1DC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE1DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _labelRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Color(0xFFDDE1DC))),
      ],
    );
  }
}
