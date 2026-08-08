import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../utils/constants.dart';

class LlmSettingsScreen extends ConsumerStatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  ConsumerState<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends ConsumerState<LlmSettingsScreen> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  double _temperature = defaultLlmTemperature;

  @override
  void initState() {
    super.initState();
    final config = ref.read(llmConfigProvider);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.model);
    _temperature = config.temperature;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final apiKey = _apiKeyController.text.trim();
    final model = _modelController.text.trim();
    if (model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a model name.')),
      );
      return;
    }
    await ref.read(llmConfigProvider.notifier).save(
          apiKey: apiKey.isEmpty ? null : apiKey,
          model: model,
          temperature: _temperature,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadFromStorage() async {
    await ref.read(llmConfigProvider.notifier).refreshFromStorage();
    if (!mounted) return;
    final config = ref.read(llmConfigProvider);
    setState(() {
      _apiKeyController.text = config.apiKey;
      _modelController.text = config.model;
      _temperature = config.temperature;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Provider')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: 'OpenRouter',
              decoration: const InputDecoration(labelText: 'Provider'),
              items: const [
                DropdownMenuItem(value: 'OpenRouter', child: Text('OpenRouter')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-or-...',
                helperText: 'Stored securely on this device',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: defaultLlmModel,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Temperature: ${_temperature.toStringAsFixed(1)}',
              style: theme.textTheme.bodyMedium,
            ),
            Slider(
              value: _temperature,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: _temperature.toStringAsFixed(1),
              onChanged: (v) => setState(() => _temperature = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: _loadFromStorage,
              child: const Text('Reload saved settings'),
            ),
          ],
        ),
      ),
    );
  }
}
