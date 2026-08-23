import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class SettingsRepository {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get allowRemoteControl => _prefs.getBool(AppConstants.keyAllowRemoteControl) ?? false;

  Future<void> setAllowRemoteControl(bool value) async {
    await _prefs.setBool(AppConstants.keyAllowRemoteControl, value);
  }

  String get turnUrl => _prefs.getString(AppConstants.keyTurnUrl) ?? 'turn:relay.metered.ca:443';
  String get turnUsername => _prefs.getString(AppConstants.keyTurnUsername) ?? 'open_source_user';
  String get turnCredential => _prefs.getString(AppConstants.keyTurnCredential) ?? 'open_source_pass';

  Future<void> saveTurnConfig(String url, String username, String credential) async {
    await _prefs.setString(AppConstants.keyTurnUrl, url);
    await _prefs.setString(AppConstants.keyTurnUsername, username);
    await _prefs.setString(AppConstants.keyTurnCredential, credential);
  }
}
