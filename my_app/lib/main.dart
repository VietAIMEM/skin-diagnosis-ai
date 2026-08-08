import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'providers/providers.dart';
import 'services/storage/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);

  runApp(ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(preferencesService),
    ],
    child: const SkinAiApp(),
  ));
}
