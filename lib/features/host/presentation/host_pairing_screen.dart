import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/code_generator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../accessibility/presentation/accessibility_guide_dialog.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/host_session_state.dart';
import 'host_provider.dart';

class HostPairingScreen extends ConsumerStatefulWidget {
  const HostPairingScreen({super.key});

  @override
  ConsumerState<HostPairingScreen> createState() => _HostPairingScreenState();
}

class _HostPairingScreenState extends ConsumerState<HostPairingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hostProvider.notifier).prepareHostSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hostState = ref.watch(hostProvider);
    final formattedCode = CodeGenerator.formatCode(hostState.sessionCode);

    ref.listen<HostSessionState>(hostProvider, (previous, next) {
      if (next.status == ConnectionStatus.connected) {
        context.push('/host/streaming');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share My Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusBadge(status: hostState.status),
              const SizedBox(height: 24),

              if (hostState.status == ConnectionStatus.creating) ...[
                const CircularProgressIndicator(color: AppTheme.primaryCyan),
                const SizedBox(height: 16),
                const Text(
                  'Starting MediaProjection & Session...',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ] else if (hostState.errorMessage != null) ...[
                Card(
                  color: AppTheme.statusError.withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.statusError, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          hostState.errorMessage!,
                          style: const TextStyle(color: AppTheme.textBright),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(hostProvider.notifier).prepareHostSession();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Pairing PIN Code',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: hostState.sessionCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pairing code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formattedCode,
                          style: const TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.copy, color: AppTheme.primaryCyan, size: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: 'remoteeye://join/${hostState.sessionCode}',
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scan with RemoteEye Viewer camera',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),

                const SizedBox(height: 32),

                // Security & Remote Control Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SwitchListTile(
                      title: const Row(
                        children: [
                          Icon(Icons.touch_app, color: AppTheme.primaryCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Allow Remote Control',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'Allows viewer to tap and swipe on your screen. Requires Accessibility Service.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      value: hostState.isRemoteControlAllowed,
                      onChanged: (val) async {
                        if (val) {
                          final settings = ref.read(settingsProvider);
                          if (!settings.isAccessibilityActive) {
                            await showDialog(
                              context: context,
                              builder: (context) => const AccessibilityGuideDialog(),
                            );
                          }
                        }
                        ref.read(hostProvider.notifier).updateAllowRemoteControl(val);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
