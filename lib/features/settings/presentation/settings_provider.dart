import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';

class SettingsState {
  final bool allowRemoteControl;
  final String turnUrl;
  final String turnUsername;
  final String turnCredential;
  final bool isAccessibilityActive;

  const SettingsState({
    required this.allowRemoteControl,
    required this.turnUrl,
    required this.turnUsername,
    required this.turnCredential,
    required this.isAccessibilityActive,
  });

  SettingsState copyWith({
    bool? allowRemoteControl,
    String? turnUrl,
    String? turnUsername,
    String? turnCredential,
    bool? isAccessibilityActive,
  }) {
    return SettingsState(
      allowRemoteControl: allowRemoteControl ?? this.allowRemoteControl,
      turnUrl: turnUrl ?? this.turnUrl,
      turnUsername: turnUsername ?? this.turnUsername,
      turnCredential: turnCredential ?? this.turnCredential,
      isAccessibilityActive: isAccessibilityActive ?? this.isAccessibilityActive,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo)
      : super(SettingsState(
          allowRemoteControl: _repo.allowRemoteControl,
          turnUrl: _repo.turnUrl,
          turnUsername: _repo.turnUsername,
          turnCredential: _repo.turnCredential,
          isAccessibilityActive: false,
        ));

  Future<void> toggleAllowRemoteControl(bool value) async {
    await _repo.setAllowRemoteControl(value);
    state = state.copyWith(allowRemoteControl: value);
  }

  Future<void> updateTurnConfig(String url, String username, String credential) async {
    await _repo.saveTurnConfig(url, username, credential);
    state = state.copyWith(
      turnUrl: url,
      turnUsername: username,
      turnCredential: credential,
    );
  }

  void updateAccessibilityStatus(bool isActive) {
    state = state.copyWith(isAccessibilityActive: isActive);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Initialize settingsRepositoryProvider in ProviderScope override');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});
