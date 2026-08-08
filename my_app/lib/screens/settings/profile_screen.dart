import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _ageController;
  String? _sex;
  String? _location;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _sex = profile.sex;
    _location = profile.lesionLocation;
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = UserProfile(
      age: int.tryParse(_ageController.text.trim()),
      sex: _sex,
      lesionLocation: _location,
    );
    await ref.read(userProfileProvider.notifier).save(profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'This information is optional and stays on your device. '
              'It is used only to personalize the AI explanation.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
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
              decoration: const InputDecoration(labelText: 'Lesion Location'),
              items: [
                for (final l in lesionLocationOptions)
                  DropdownMenuItem(value: l, child: Text(l)),
              ],
              onChanged: (v) => setState(() => _location = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
