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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied!'),
          ],
        ),
        backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.85),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _shareText(String text) {
    // Use MethodChannel to call Android's share sheet
    const platform = MethodChannel('com.example.remote_eye/share');
    platform.invokeMethod('shareText', {'text': text}).catchError((_) {
      // Fallback: just copy to clipboard
      _copyToClipboard(text, 'Connection info');
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusBadge(status: hostState.status),
              const SizedBox(height: 16),

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

                // ─── HOST IP ADDRESS CARD ─────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryCyan.withValues(alpha: 0.18),
                        AppTheme.darkSurface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.wifi_tethering,
                                color: AppTheme.primaryCyan,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HOST IP ADDRESS',
                                  style: TextStyle(
                                    color: AppTheme.primaryCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  'Share this with the viewer',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Big IP address text
                        Center(
                          child: SelectableText(
                            hostState.hostIp.isNotEmpty ? hostState.hostIp : '—',
                            style: const TextStyle(
                              color: AppTheme.textBright,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Port: 8080',
                            style: TextStyle(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.7),
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action buttons row: Copy IP | Copy Full | Share
                        Row(
                          children: [
                            // Copy IP only
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.copy,
                                label: 'Copy IP',
                                onTap: () => _copyToClipboard(
                                  hostState.hostIp,
                                  'IP address',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Copy IP:Port
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.link,
                                label: 'Copy IP:Port',
                                onTap: () => _copyToClipboard(
                                  '${hostState.hostIp}:8080',
                                  'IP:Port',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Share button
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.share,
                                label: 'Share',
                                onTap: () => _shareText(
                                  'RemoteEye Session\nIP: ${hostState.hostIp}\nPort: 8080\nPIN: $formattedCode\n\nScan QR or enter IP in RemoteEye Viewer app.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ─── PAIRING PIN ──────────────────────────────────────────
                const Text(
                  'PAIRING PIN',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: () => _copyToClipboard(hostState.sessionCode, 'PIN code'),
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
                const SizedBox(height: 20),

                // ─── QR CODE ──────────────────────────────────────────────
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
                    data: hostState.qrData.isNotEmpty
                        ? hostState.qrData
                        : 'remoteeye://join/${hostState.hostIp}:8080',
                    version: QrVersions.auto,
                    size: 190.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan with RemoteEye Viewer camera to join instantly',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),

                const SizedBox(height: 20),

                // ─── REMOTE CONTROL TOGGLE ────────────────────────────────
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

/// Compact tappable action button used in the IP address card
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.darkBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryCyan.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.primaryCyan, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
