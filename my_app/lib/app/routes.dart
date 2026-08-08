import 'package:flutter/material.dart';

import '../screens/chat/chat_screen.dart';
import '../screens/diagnosis/diagnosis_result_screen.dart';
import '../screens/diagnosis/image_preview_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/settings/llm_settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  static const onboarding = '/onboarding';
  static const chat = '/chat';
  static const settings = '/settings';
  static const profile = '/settings/profile';
  static const llmSettings = '/settings/llm';
  static const imagePreview = '/diagnosis/preview';
  static const diagnosisResult = '/diagnosis/result';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case onboarding:
        return _page(const OnboardingScreen());
      case chat:
        return _page(const ChatScreen());
      case settings:
        return _page(const SettingsScreen());
      case profile:
        return _page(const ProfileScreen());
      case llmSettings:
        return _page(const LlmSettingsScreen());
      case imagePreview:
        return _page(ImagePreviewScreen(args: routeSettings.arguments));
      case diagnosisResult:
        return _page(DiagnosisResultScreen(args: routeSettings.arguments));
      default:
        return _page(const ChatScreen());
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child) {
    return MaterialPageRoute<dynamic>(builder: (_) => child);
  }
}
