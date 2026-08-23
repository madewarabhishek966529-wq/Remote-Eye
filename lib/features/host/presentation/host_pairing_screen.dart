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
              const SizedBox(height: 20),

              if (hostState.status == ConnectionStatus.creating) ...[
                const CircularProgressIndicator(color: AppTheme.primaryCyan),
                const SizedBox(height: 16),
                const Text(
                  'Starting Embedded Local Signaling Server...',
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
                // Host IP Address display pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi, color: AppTheme.primaryCyan, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Host IP: ${hostState.hostIp}',
                        style: const TextStyle(
                          color: AppTheme.textBright,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Pairing PIN Code',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: hostState.hostIp));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Host IP copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.copy, color: AppTheme.primaryCyan, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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
                    data: hostState.qrData.isNotEmpty ? hostState.qrData : 'remoteeye://join/${hostState.hostIp}:8080',
                    version: QrVersions.auto,
                    size: 190.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Scan with RemoteEye Viewer camera to join instantly',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),

                const SizedBox(height: 24),

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
