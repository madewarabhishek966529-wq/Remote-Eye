import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_badge.dart';
import 'viewer_provider.dart';

class ViewerStreamScreen extends ConsumerStatefulWidget {
  const ViewerStreamScreen({super.key});

  @override
  ConsumerState<ViewerStreamScreen> createState() => _ViewerStreamScreenState();
}

class _ViewerStreamScreenState extends ConsumerState<ViewerStreamScreen> {
  Offset? _panStartOffset;
  DateTime? _panStartTime;
  bool _isControlsVisible = true;

  @override
  Widget build(BuildContext context) {
    final viewerState = ref.watch(viewerProvider);
    final repository = ref.watch(viewerWebRtcRepositoryProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeaveSession(context);
        if (shouldLeave) {
          await ref.read(viewerProvider.notifier).leaveSession();
          if (context.mounted) {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Remote Video Renderer & Touch Relay Overlay
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isControlsVisible = !_isControlsVisible;
                        });
                      },
                      onTapUp: (details) {
                        if (!viewerState.isTouchControlActive) return;
                        final xPct = details.localPosition.dx / constraints.maxWidth;
                        final yPct = details.localPosition.dy / constraints.maxHeight;
                        ref.read(viewerProvider.notifier).sendTap(xPct, yPct);
                      },
                      onDoubleTapDown: (details) {
                        if (!viewerState.isTouchControlActive) return;
                        final xPct = details.localPosition.dx / constraints.maxWidth;
                        final yPct = details.localPosition.dy / constraints.maxHeight;
                        ref.read(viewerProvider.notifier).sendDoubleTap(xPct, yPct);
                      },
                      onLongPressStart: (details) {
                        if (!viewerState.isTouchControlActive) return;
                        final xPct = details.localPosition.dx / constraints.maxWidth;
                        final yPct = details.localPosition.dy / constraints.maxHeight;
                        ref.read(viewerProvider.notifier).sendLongPress(xPct, yPct);
                      },
                      onPanStart: (details) {
                        _panStartOffset = details.localPosition;
                        _panStartTime = DateTime.now();
                      },
                      onPanEnd: (details) {
                        if (!viewerState.isTouchControlActive || _panStartOffset == null || _panStartTime == null) return;
                        final endOffset = details.localPosition;
                        final durationMs = DateTime.now().difference(_panStartTime!).inMilliseconds;

                        // Ignore tiny movements that were meant to be taps
                        final distance = (endOffset - _panStartOffset!).distance;
                        if (distance > 15) {
                          final startXPct = _panStartOffset!.dx / constraints.maxWidth;
                          final startYPct = _panStartOffset!.dy / constraints.maxHeight;
                          final endXPct = endOffset.dx / constraints.maxWidth;
                          final endYPct = endOffset.dy / constraints.maxHeight;

                          ref.read(viewerProvider.notifier).sendSwipe(
                                startX: startXPct,
                                startY: startYPct,
                                endX: endXPct,
                                endY: endYPct,
                                durationMs: durationMs.clamp(100, 1000),
                              );
                        }
                      },
                      child: RTCVideoView(
                        repository.remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      ),
                    );
                  },
                ),
              ),

              // Loading / Connecting Overlay
              if (viewerState.status != ConnectionStatus.connected)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primaryCyan),
                          const SizedBox(height: 16),
                          StatusBadge(status: viewerState.status),
                          const SizedBox(height: 8),
                          Text(
                            'Connecting to Host PIN ${viewerState.sessionCode}...',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Top Status & Latency Header Bar
              if (_isControlsVisible)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        StatusBadge(status: viewerState.status),
                        const Spacer(),

                        // Latency & Quality Indicator
                        if (viewerState.status == ConnectionStatus.connected) ...[
                          Icon(
                            Icons.speed,
                            size: 16,
                            color: viewerState.latencyMs < 100 ? AppTheme.statusGreen : AppTheme.statusWarning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${viewerState.latencyMs} ms',
                            style: TextStyle(
                              color: viewerState.latencyMs < 100 ? AppTheme.statusGreen : AppTheme.statusWarning,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Close Button
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.statusError),
                          onPressed: () async {
                            final shouldLeave = await _confirmLeaveSession(context);
                            if (shouldLeave) {
                              await ref.read(viewerProvider.notifier).leaveSession();
                              if (context.mounted) {
                                context.go('/');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom Control & Android Navigation Bar
              if (_isControlsVisible && viewerState.status == ConnectionStatus.connected)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Touch Control Toggle
                        IconButton(
                          icon: Icon(
                            viewerState.isTouchControlActive ? Icons.touch_app : Icons.touch_app_outlined,
                            color: viewerState.isTouchControlActive ? AppTheme.primaryCyan : AppTheme.textMuted,
                          ),
                          tooltip: 'Toggle Remote Control Touch Relay',
                          onPressed: () {
                            ref.read(viewerProvider.notifier).toggleTouchControl(!viewerState.isTouchControlActive);
                          },
                        ),

                        const SizedBox(width: 8),
                        Container(width: 1, height: 24, color: AppTheme.darkSurface),
                        const SizedBox(width: 8),

                        // Back Button
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.textBright),
                          tooltip: 'Android Back',
                          onPressed: () => ref.read(viewerProvider.notifier).sendGlobalAction('back'),
                        ),

                        // Home Button
                        IconButton(
                          icon: const Icon(Icons.circle_outlined, color: AppTheme.textBright),
                          tooltip: 'Android Home',
                          onPressed: () => ref.read(viewerProvider.notifier).sendGlobalAction('home'),
                        ),

                        // Recents Button
                        IconButton(
                          icon: const Icon(Icons.crop_square, color: AppTheme.textBright),
                          tooltip: 'Android Recent Apps',
                          onPressed: () => ref.read(viewerProvider.notifier).sendGlobalAction('recents'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmLeaveSession(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Disconnect from Host?'),
        content: const Text('Are you sure you want to end live mirroring?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusError),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
