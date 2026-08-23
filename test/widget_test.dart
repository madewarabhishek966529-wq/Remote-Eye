import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_eye/app.dart';
import 'package:remote_eye/features/settings/data/settings_repository.dart';
import 'package:remote_eye/features/settings/presentation/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('RemoteEye app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settingsRepo = SettingsRepository();
    await settingsRepo.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
        child: const RemoteEyeApp(),
      ),
    );

    expect(find.text('RemoteEye'), findsOneWidget);
  });
}
