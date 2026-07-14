import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../utils/constants.dart';
import '../widgets/centered_content.dart';
import '../widgets/adventure_chip.dart';
import '../widgets/user_avatar.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    this.isEditing = false,
    this.initialStep = 0,
  });

  final bool isEditing;
  final int initialStep;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final PageController _pageCtrl; // Change to late final
  late int _currentStep; // Change to late

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  String _skillLevel = kSkillLevels.first;

  int _age = 25;
  int _targetAgeStart = 18;
  int _targetAgeEnd = 75;
  String? _gender;
  String? _interestedIn;
  final Set<String> _selectedAdventures = {};
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller and step with the new widget property
    _pageCtrl = PageController(initialPage: widget.initialStep);
    _currentStep = widget.initialStep;

    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final parts = user.name.split(' ');
      _firstNameCtrl.text = parts.isNotEmpty ? parts[0] : '';
      _lastNameCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _locationCtrl.text = user.location ?? '';
      _bioCtrl.text = user.bio;
      _age = user.age > 0 ? user.age : 25;
      _targetAgeStart = user.targetAgeStart ?? 18;
      _targetAgeEnd = user.targetAgeEnd ?? 75;
      _gender = user.gender;
      _interestedIn = user.interestedIn;
      _selectedAdventures.addAll(user.adventureTypes);
      _instagramCtrl.text = user.instagramHandle ?? '';
      _skillLevel = kSkillLevels.contains(user.skillLevel)
          ? user.skillLevel
          : kSkillLevels.first;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void _previousPage() {
    if (_currentStep == 0) {
      if (widget.isEditing) {
        Navigator.pop(context);
      }
      return;
    }

    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _save() async {
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
    final trimmedInstagramHandle = _instagramCtrl.text.trim();
    final updated = auth.currentUser!.copyWith(
      name: '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim(),
      age: _age,
      targetAgeStart: _targetAgeStart,
      targetAgeEnd: _targetAgeEnd,
      gender: _gender,
      interestedIn: _interestedIn,
      bio: _bioCtrl.text.trim(),
      instagramHandle: trimmedInstagramHandle.isEmpty
          ? null
          : trimmedInstagramHandle.replaceFirst(RegExp(r'^@+'), ''),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      adventureTypes: _selectedAdventures.toList(),
      skillLevel: _skillLevel,
    );

    try {
      await auth.updateCurrentUser(updated);

      if (!mounted) return;
      await context.read<MatchProvider>().load(updated);

      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.pop(context);
        return;
      }

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Unable to save your profile right now.',
          ),
          backgroundColor: AppColors.pass,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _uploadPhoto() async {
    setState(() => _uploadingPhoto = true);

    final photoUrl = await context.read<AuthProvider>().uploadProfilePhoto();

    if (!mounted) {
      return;
    }

    setState(() => _uploadingPhoto = false);
    if (photoUrl == null) {
      final message = context.read<AuthProvider>().errorMessage;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Your Profile' : 'Create Your Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: widget.isEditing || _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _saving ? null : _previousPage,
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: CenteredContent(
                maxWidth: 720,
                child: Column(
                  children: [
                    _buildProgressBar(),
                    Expanded(
                      child: PageView(
                        controller: _pageCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (i) => setState(() => _currentStep = i),
                        children: [
                          _buildStep1(),
                          _buildStepIdentity(),
                          _buildStep2(),
                        ],
                      ),
                    ),
                    _buildBottomButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _progressSegment(0)),
              const SizedBox(width: 8),
              Expanded(child: _progressSegment(1)),
              const SizedBox(width: 8),
              Expanded(child: _progressSegment(2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressSegment(int step) {
    final active = _currentStep >= step;
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStep1() {
    final user = context.watch<AuthProvider>().currentUser;
    final hasPhoto = user?.photoUrl?.trim().isNotEmpty ?? false;
    final initial = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().substring(0, 1).toUpperCase()
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adventurer Essentials',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                UserAvatar(
                  size: 104,
                  photoUrl: hasPhoto ? user!.photoUrl : null,
                  backgroundColor: AppColors.primary.withAlpha(180),
                  fallback: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _uploadingPhoto || _saving ? null : _uploadPhoto,
                  icon: _uploadingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(hasPhoto ? 'Change Photo' : 'Upload Photo'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Optional. One compressed photo only.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _underlineField(_firstNameCtrl, 'First Name'),
          const SizedBox(height: 24),
          _underlineField(_lastNameCtrl, 'Last Name'),
          const SizedBox(height: 24),
          _buildAgeRow(),
          const SizedBox(height: 24),
          _underlineField(_locationCtrl, 'Location'),
          const SizedBox(height: 24),
          _underlineField(_instagramCtrl, 'Instagram Handle'),
          const SizedBox(height: 24),
          _buildDropdownField(
            label: 'Skill Level',
            value: _skillLevel,
            options: kSkillLevels,
            onChanged: (value) {
              if (value != null) {
                setState(() => _skillLevel = value);
              }
            },
          ),
          const SizedBox(height: 24),
          _underlineField(_bioCtrl, 'Bio', maxLines: 4),
        ],
      ),
    );
  }

  Widget _buildStepIdentity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Identity & Preferences',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about yourself and who you are looking for.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          const Text(
            'My Gender Identity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: ['Male', 'Female', 'Non-Binary', 'Other'],
            selected: _gender,
            onSelected: (val) => setState(() => _gender = val),
          ),
          const SizedBox(height: 32),
          const Text(
            'Interested In',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: ['Male', 'Female', 'Non-Binary', 'Other', 'Any'],
            selected: _interestedIn,
            onSelected: (val) => setState(() => _interestedIn = val),
          ),
          const SizedBox(height: 32),
          _buildTargetAgeRow(),
        ],
      ),
    );
  }

  Widget _buildTargetAgeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Target Age Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$_targetAgeStart - $_targetAgeEnd',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(
            _targetAgeStart.toDouble(),
            _targetAgeEnd.toDouble(),
          ),
          min: 18,
          max: 75,
          divisions: 57,
          activeColor: AppColors.primary,
          inactiveColor: Colors.grey[200],
          onChanged: (range) => setState(() {
            _targetAgeStart = range.start.toInt();
            _targetAgeEnd = range.end.toInt();
          }),
        ),
      ],
    );
  }

  Widget _buildSelectionGrid({
    required List<String> options,
    required String? selected,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((opt) {
        final isSel = selected == opt;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSel ? AppColors.primary : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adventure Style',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'What gets your heart racing?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
        ],
      ),
    );
  }

  Widget _underlineField(
    TextEditingController ctrl,
    String label, {
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAgeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Age',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            Text(
              '$_age',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Slider(
          value: _age.toDouble(),
          min: 18,
          max: 75,
          divisions: 57,
          activeColor: AppColors.primary,
          inactiveColor: Colors.grey[200],
          onChanged: (v) => setState(() => _age = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _saving ? null : _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'BACK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _currentStep == 2 ? 'FINISH' : 'NEXT',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
