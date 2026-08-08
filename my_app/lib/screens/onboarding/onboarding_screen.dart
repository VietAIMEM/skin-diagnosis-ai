import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

/// First-run onboarding. Personal information is optional and skippable.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ageController = TextEditingController();
  String? _sex;
  String? _location;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final profile = _buildProfile();
    if (!profile.isEmpty) {
      await ref.read(userProfileProvider.notifier).save(profile);
    }
    await ref.read(preferencesServiceProvider).setOnboardingCompleted();
    // Rebuild the whole app: onboarding provider flips to true.
    ref.invalidate(onboardingProvider);
  }

  UserProfile _buildProfile() {
    final age = int.tryParse(_ageController.text.trim());
    return UserProfile(
      age: age,
      sex: _sex,
      lesionLocation: _location,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.spa_rounded, size: 64, color: Colors.teal),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to $appName',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'I can help you understand skin lesion image analysis '
                    'results.\n\nYou can optionally provide some information '
                    'to personalize the conversation.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      hintText: 'e.g. 34',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _sex,
                    decoration: const InputDecoration(labelText: 'Sex'),
                    items: [
                      for (final s in sexOptions)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => setState(() => _sex = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _location,
                    decoration:
                        const InputDecoration(labelText: 'Lesion Location'),
                    items: [
                      for (final l in lesionLocationOptions)
                        DropdownMenuItem(value: l, child: Text(l)),
                    ],
                    onChanged: (v) => setState(() => _location = v),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _continue,
                    child: const Text('Continue'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _continue,
                    child: const Text('Skip for now'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This is an AI-assisted image classification tool. '
                    'It is not a medical diagnosis. Please consult a '
                    'qualified healthcare professional for medical advice.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
