import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/status_badge.dart';
import 'host_provider.dart';

class HostStreamingScreen extends ConsumerWidget {
  const HostStreamingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostState = ref.watch(hostProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldEnd = await _confirmEndSession(context);
        if (shouldEnd) {
          await ref.read(hostProvider.notifier).endSession();
          if (context.mounted) {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Screen Sharing'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                const BrandLogo(size: 100),
                const SizedBox(height: 24),
                StatusBadge(status: hostState.status),
                const SizedBox(height: 16),
                Text(
                  hostState.status == ConnectionStatus.connected
                      ? 'Your screen is being mirrored in real time'
                      : 'Connecting / Reconnecting screen stream...',
                  style: const TextStyle(color: AppTheme.textBright, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card showing status and remote control status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Session PIN:', style: TextStyle(color: AppTheme.textMuted)),
                            Text(
                              hostState.sessionCode,
                              style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppTheme.darkSurface),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Remote Touch Relay:', style: TextStyle(color: AppTheme.textMuted)),
                            Row(
                              children: [
                                Icon(
                                  hostState.isRemoteControlAllowed ? Icons.touch_app : Icons.touch_app_outlined,
                                  size: 16,
                                  color: hostState.isRemoteControlAllowed ? AppTheme.statusGreen : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hostState.isRemoteControlAllowed ? 'ENABLED' : 'DISABLED',
                                  style: TextStyle(
                                    color: hostState.isRemoteControlAllowed ? AppTheme.statusGreen : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // End Sharing Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final shouldEnd = await _confirmEndSession(context);
                      if (shouldEnd) {
                        await ref.read(hostProvider.notifier).endSession();
                        if (context.mounted) {
                          context.go('/');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusError,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('Stop Sharing Screen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmEndSession(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Stop Screen Sharing?'),
        content: const Text('This will disconnect the remote viewer immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusError),
            child: const Text('Stop Sharing'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
