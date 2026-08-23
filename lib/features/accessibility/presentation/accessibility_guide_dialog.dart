import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/accessibility_native_service.dart';

class AccessibilityGuideDialog extends StatelessWidget {
  const AccessibilityGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.primaryCyan, width: 1),
      ),
      title: const Row(
        children: [
          Icon(Icons.touch_app, color: AppTheme.primaryCyan, size: 28),
          SizedBox(width: 12),
          Text(
            'Enable Remote Control',
            style: TextStyle(color: AppTheme.textBright, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To allow the remote viewer to tap and swipe on your device, RemoteEye requires Accessibility Service permission.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildStep('1', 'Tap "Open Settings" below.'),
            _buildStep('2', 'Find "RemoteEye Gesture Controller" under Installed Services.'),
            _buildStep('3', 'Toggle the service ON and confirm the permission prompt.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.statusWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.statusWarning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: AppTheme.statusWarning, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remote control is optional. Screen mirroring will work even if this is turned off.',
                      style: TextStyle(color: AppTheme.textBright, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final nativeService = AccessibilityNativeService();
            await nativeService.openAccessibilitySettings();
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('Open Settings'),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppTheme.primaryCyan,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.darkBackground,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textBright, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
