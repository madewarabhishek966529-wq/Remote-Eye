import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../accessibility/data/accessibility_native_service.dart';
import '../../accessibility/presentation/accessibility_guide_dialog.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _credentialController;
  final AccessibilityNativeService _nativeService = AccessibilityNativeService();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _urlController = TextEditingController(text: settings.turnUrl);
    _usernameController = TextEditingController(text: settings.turnUsername);
    _credentialController = TextEditingController(text: settings.turnCredential);
    _checkAccessibility();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  Future<void> _checkAccessibility() async {
    final granted = await _nativeService.isAccessibilityGranted();
    if (mounted) {
      ref.read(settingsProvider.notifier).updateAccessibilityStatus(granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Security & Remote Control'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Allow Remote Touch Control',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBright),
                    ),
                    subtitle: const Text(
                      'Enables viewers to send taps and swipes to control your screen. Default is OFF for privacy.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    value: settings.allowRemoteControl,
                    onChanged: (val) async {
                      if (val && !settings.isAccessibilityActive) {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const AccessibilityGuideDialog(),
                        );
                        if (result == true) {
                          _checkAccessibility();
                        }
                      }
                      ref.read(settingsProvider.notifier).toggleAllowRemoteControl(val);
                    },
                  ),
                  const Divider(color: AppTheme.darkSurface),
                  ListTile(
                    leading: Icon(
                      settings.isAccessibilityActive ? Icons.check_circle : Icons.warning_amber,
                      color: settings.isAccessibilityActive ? AppTheme.statusGreen : AppTheme.statusWarning,
                    ),
                    title: const Text(
                      'Accessibility Service Status',
                      style: TextStyle(color: AppTheme.textBright, fontSize: 14),
                    ),
                    subtitle: Text(
                      settings.isAccessibilityActive
                          ? 'Active (Gestures ready)'
                          : 'Inactive (Tap to configure)',
                      style: TextStyle(
                        color: settings.isAccessibilityActive ? AppTheme.statusGreen : AppTheme.statusWarning,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryCyan),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => const AccessibilityGuideDialog(),
                      );
                      _checkAccessibility();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('WebRTC ICE & TURN Server Config'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STUN: stun:stun.l.google.com:19302 (Default Google Public STUN)',
                    style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'TURN Server URL',
                      hintText: 'turn:relay.metered.ca:443',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'TURN Username',
                      hintText: 'Username',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _credentialController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'TURN Password / Credential',
                      hintText: 'Credential',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(settingsProvider.notifier).updateTurnConfig(
                              _urlController.text.trim(),
                              _usernameController.text.trim(),
                              _credentialController.text.trim(),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('TURN Server configuration saved!'),
                            backgroundColor: AppTheme.statusGreen,
                          ),
                        );
                      },
                      child: const Text('Save TURN Configuration'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'RemoteEye v1.0.0 • Production Quality P2P WebRTC',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryCyan,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
