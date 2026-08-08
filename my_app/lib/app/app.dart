import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../utils/constants.dart';
import 'routes.dart';
import 'theme.dart';

/// Root widget wiring the theme, routes and providers.
class SkinAiApp extends ConsumerWidget {
  const SkinAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final onboarding = ref.watch(onboardingProvider);

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: onboarding ? const ChatScreen() : const OnboardingScreen(),
    );
  }
}
