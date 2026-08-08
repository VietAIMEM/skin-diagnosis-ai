import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/llm_config.dart';
import '../../models/user_profile.dart';
import '../../utils/constants.dart';

/// Persists non-sensitive application preferences locally.
class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  // Onboarding
  bool get onboardingCompleted =>
      _prefs.getBool(kOnboardingCompleted) ?? false;
  Future<void> setOnboardingCompleted() =>
      _prefs.setBool(kOnboardingCompleted, true);

  // Model selection
  String get analysisModelOptionKey =>
      _prefs.getString(kAnalysisModelOption) ?? defaultModelId;
  Future<void> setAnalysisModelOption(String value) =>
      _prefs.setString(kAnalysisModelOption, value);

  AnalysisModelOption get analysisModelOption {
    switch (analysisModelOptionKey) {
      case modelIdBaseline:
        return AnalysisModelOption.baseline;
      case modelIdSmartphone:
        return AnalysisModelOption.smartphone;
      default:
        return AnalysisModelOption.compareBoth;
    }
  }

  // LLM settings
  String get llmModel => _prefs.getString(kLlmModel) ?? defaultLlmModel;
  Future<void> setLlmModel(String value) => _prefs.setString(kLlmModel, value);

  double get llmTemperature =>
      _prefs.getDouble(kLlmTemperature) ?? defaultLlmTemperature;
  Future<void> setLlmTemperature(double value) =>
      _prefs.setDouble(kLlmTemperature, value);

  Future<LlmConfig> loadLlmConfig({String apiKey = ''}) async {
    return LlmConfig(
      apiKey: apiKey,
      model: llmModel,
      temperature: llmTemperature,
    );
  }

  // User profile
  static const _profileKey = 'user_profile';

  UserProfile? get profile {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) =>
      _prefs.setString(_profileKey, jsonEncode(profile.toJson()));

  // Theme
  String? get themeMode => _prefs.getString(kThemeMode);
  Future<void> setThemeMode(String value) => _prefs.setString(kThemeMode, value);

  // Language
  String get language => _prefs.getString(kLanguage) ?? 'English';
  Future<void> setLanguage(String value) => _prefs.setString(kLanguage, value);

  Future<void> clearAll() => _prefs.clear();
}
