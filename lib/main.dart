import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/logger.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SharedPreferences & Settings
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();

  // 2. Initialize Firebase Core
  try {
    await Firebase.initializeApp();
    AppLogger.i('Main', 'Firebase initialized successfully');
  } catch (e) {
    AppLogger.w(
      'Main',
      'Firebase.initializeApp default options notice: Ensure android/app/google-services.json is placed for live cloud connection.',
    );
  }

  // 3. Launch App with Riverpod ProviderScope
  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
      child: const RemoteEyeApp(),
    ),
  );
}
