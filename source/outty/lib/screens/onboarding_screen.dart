import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.user, required this.onComplete});

  final User user;
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final List<String> _adventureLikes = <String>[
    'Hiking',
    'Camping',
    'Cycling',
    'Kayaking',
    'Climbing',
    'Backpacking',
    'Traveling',
  ];
  int _step = 0;
  final List<String> _selectedAdventureLikes = <String>[];
  double _distancePreference = 25;
  RangeValues _ageRange = const RangeValues(18, 45);
  bool _isSaving = false;

  final _pictureUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _pictureUrlController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_nameController.text.trim().isEmpty || _ageController.text.trim().isEmpty) {
      _showMessage('Please add your name and age before continuing.');
      return;
    }

    if (_selectedAdventureLikes.isEmpty) {
      _showMessage('Select at least one adventure you enjoy.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final age = int.parse(_ageController.text.trim());
      await widget.user.updateDisplayName(_nameController.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'uid': widget.user.uid,
        'email': widget.user.email,
        'displayName': _nameController.text.trim(),
        'name': _nameController.text.trim(),
        'age': age,
        'pictureUrl': _pictureUrlController.text.trim(),
        'bio': _bioController.text.trim(),
        'adventureLikes': _selectedAdventureLikes,
        'distancePreferenceMiles': _distancePreference.round(),
        'agePreferenceRange': {
          'min': _ageRange.start.round(),
          'max': _ageRange.end.round(),
        },
        'onboardingComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      widget.onComplete();
    } catch (error) {
      await _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Something went wrong'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Welcome to Outty')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: (_step + 1) / 3),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _step == 0
                        ? _buildProfileStep()
                        : _step == 1
                            ? _buildAdventureLikesStep()
                            : _buildMatchingStep(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_step == 2) {
                                _finishOnboarding();
                              } else if (_step == 0) {
                                if (_nameController.text.trim().isEmpty || _ageController.text.trim().isEmpty) {
                                  _showMessage('Please enter your name and age.');
                                } else {
                                  setState(() => _step++);
                                }
                              } else if (_step == 1) {
                                if (_selectedAdventureLikes.isEmpty) {
                                  _showMessage('Select at least one adventure like.');
                                } else {
                                  setState(() => _step++);
                                }
                              }
                            },
                      child: Text(_step == 2 ? 'Start Exploring' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about yourself', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Add a few details so other adventurers can get to know you.'),
          const SizedBox(height: 20),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(
            controller: _ageController,
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pictureUrlController,
            decoration: const InputDecoration(
              labelText: 'Profile picture URL (optional)',
              hintText: 'https://example.com/photo.jpg',
              prefixIcon: Icon(Icons.image),
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
          if (_pictureUrlController.text.trim().isNotEmpty) ...[  
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _pictureUrlController.text.trim(),
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, e, stack) => Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Short bio'),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildAdventureLikesStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick your adventure likes', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Choose the activities you most want to share with other explorers.'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _adventureLikes.map((like) {
              final isSelected = _selectedAdventureLikes.contains(like);
              return FilterChip(
                label: Text(like),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    if (isSelected) {
                      _selectedAdventureLikes.remove(like);
                    } else {
                      _selectedAdventureLikes.add(like);
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

  Widget _buildMatchingStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customize your matches', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Set how far you want to explore and the age range you prefer.'),
          const SizedBox(height: 20),
          Text('Distance: ${_distancePreference.round()} miles'),
          Slider(
            value: _distancePreference,
            min: 5,
            max: 100,
            divisions: 19,
            label: '${_distancePreference.round()} miles',
            onChanged: (value) => setState(() => _distancePreference = value),
          ),
          const SizedBox(height: 12),
          Text('Preferred age range: ${_ageRange.start.round()}-${_ageRange.end.round()}'),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 70,
            divisions: 52,
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: (values) => setState(() => _ageRange = values),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Match me with people who enjoy ${_selectedAdventureLikes.join(', ')}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
