import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/extensions.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final llmConfig = ref.watch(llmConfigProvider);
    final profile = ref.watch(userProfileProvider);
    final analysisModel = ref.watch(analysisModelProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle(theme, 'PROFILE'),
            _settingsTile(
              theme,
              icon: Icons.person_outline,
              title: 'Personal Information',
              subtitle: profile.isEmpty
                  ? 'Not provided'
                  : (profile.age != null ? 'Age ${profile.age} · ' : '') +
                      (profile.sex ?? '') +
                      (profile.lesionLocation != null
                          ? ' · ${profile.lesionLocation}'
                          : ''),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, 'AI'),
            _settingsTile(
              theme,
              icon: Icons.smart_toy_outlined,
              title: 'LLM Provider',
              subtitle: llmConfig.provider,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.llmSettings),
            ),
            _settingsTile(
              theme,
              icon: Icons.key_outlined,
              title: 'API Key',
              subtitle: llmConfig.hasApiKey
                  ? llmConfig.apiKey.maskedKey()
                  : 'Not configured',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.llmSettings),
            ),
            _settingsTile(
              theme,
              icon: Icons.model_training_outlined,
              title: 'Model',
              subtitle: llmConfig.model,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.llmSettings),
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, 'DIAGNOSIS'),
            _settingsTile(
              theme,
              icon: Icons.analytics_outlined,
              title: 'Analysis Model',
              subtitle: _modelLabel(analysisModel),
              onTap: () => _showModelPicker(context, ref),
            ),
            SwitchListTile(
              value: analysisModel == AnalysisModelOption.compareBoth,
              onChanged: (v) => ref
                  .read(analysisModelProvider.notifier)
                  .setOption(v
                      ? AnalysisModelOption.compareBoth
                      : AnalysisModelOption.smartphone),
              title: const Text('Compare Models'),
              subtitle: const Text('Run both models and show comparison'),
              secondary: const Icon(Icons.compare_arrows_outlined),
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, 'APP'),
            _settingsTile(
              theme,
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: ref.read(preferencesServiceProvider).language,
              onTap: () => _showLanguagePicker(context, ref),
            ),
            _settingsTile(
              theme,
              icon: Icons.brightness_6_outlined,
              title: 'Theme',
              subtitle: _themeLabel(themeMode),
              onTap: () => _showThemePicker(context, ref),
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, 'DATA'),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Chat History'),
              onTap: () => _confirmClear(context, ref),
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, 'ABOUT'),
            _settingsTile(
              theme,
              icon: Icons.info_outline,
              title: 'About SkinAI',
              subtitle: 'On-device skin lesion analysis AI chatbot',
              onTap: () => _showAbout(context),
            ),
            _settingsTile(
              theme,
              icon: Icons.health_and_safety_outlined,
              title: 'Medical Disclaimer',
              subtitle: 'Important safety information',
              onTap: () => _showDisclaimer(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _settingsTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _modelLabel(AnalysisModelOption option) {
    return switch (option) {
      AnalysisModelOption.smartphone => 'Smartphone Optimized',
      AnalysisModelOption.baseline => 'Baseline',
      AnalysisModelOption.compareBoth => 'Compare Both',
    };
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  void _showModelPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(analysisModelProvider);
    _showSelectionDialog(
      context,
      title: 'Analysis Model',
      options: AnalysisModelOption.values
          .map((o) => (label: _modelLabel(o), value: o))
          .toList(),
      selected: current,
      onSelect: (o) => ref.read(analysisModelProvider.notifier).setOption(o),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    const languages = ['English', 'Vietnamese'];
    final current = ref.read(preferencesServiceProvider).language;
    _showSelectionDialog(
      context,
      title: 'Language',
      options: [
        for (final l in languages) (label: l, value: l),
      ],
      selected: current,
      onSelect: (l) => ref.read(preferencesServiceProvider).setLanguage(l),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    _showSelectionDialog(
      context,
      title: 'Theme',
      options: [
        for (final mode in ThemeMode.values)
          (label: _themeLabel(mode), value: mode),
      ],
      selected: current,
      onSelect: (m) => ref.read(themeModeProvider.notifier).setMode(m),
    );
  }

  Future<void> _showSelectionDialog<T>(
    BuildContext context, {
    required String title,
    required List<({String label, T value})> options,
    required T selected,
    required ValueChanged<T> onSelect,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final option in options)
            ListTile(
              title: Text(option.label),
              trailing: option.value == selected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(ctx).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                onSelect(option.value);
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('This will permanently delete your chat history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(chatProvider.notifier).clearHistory();
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.spa_rounded, size: 48, color: Colors.teal),
      children: const [
        Text(
          'An on-device skin lesion image analysis chatbot.\n\n'
          'The image classification model runs locally on your device. '
          'The AI explanation is powered by an external LLM service that '
          'you configure. No custom backend is used.',
        ),
      ],
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Medical Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'This application is an AI-assisted image classification tool. '
            'It is not a medical diagnosis.\n\n'
            '- Results can be incorrect.\n'
            '- The AI explanation does not replace professional examination.\n'
            '- You should consult a qualified healthcare professional.\n\n'
            'The classification model provides probabilistic predictions only '
            'and should never be used as the sole basis for any medical decision.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
