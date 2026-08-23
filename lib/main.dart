import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/logger.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SharedPreferences & Local Settings
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();
  AppLogger.i('Main', 'RemoteEye initialized in 100% standalone cloud-free mode');

  // 2. Launch App with Riverpod ProviderScope
  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
      child: const RemoteEyeApp(),
    ),
  );
}
