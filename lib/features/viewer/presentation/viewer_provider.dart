import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/widgets/status_badge.dart';
import '../../host/presentation/host_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../data/viewer_webrtc_repository.dart';
import '../domain/viewer_session_state.dart';

final viewerWebRtcRepositoryProvider = Provider<ViewerWebRtcRepository>((ref) {
  final signalingService = ref.watch(localSignalingProvider);
  return ViewerWebRtcRepository(signalingService);
});

class ViewerNotifier extends StateNotifier<ViewerSessionState> {
  final ViewerWebRtcRepository _repository;
  final Ref _ref;

  ViewerNotifier(this._repository, this._ref) : super(ViewerSessionState.initial());

  Future<void> joinSession(String hostTarget) async {
    String cleanTarget = hostTarget.trim();
    if (cleanTarget.contains('remoteeye://join/')) {
      cleanTarget = cleanTarget.replaceAll('remoteeye://join/', '').trim();
    }
    if (cleanTarget.contains(':')) {
      cleanTarget = cleanTarget.split(':')[0];
    }

    if (cleanTarget.isEmpty) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: 'Please enter a valid Host IP address or scan QR code.',
      );
      return;
    }

    state = state.copyWith(
      sessionCode: cleanTarget,
      status: ConnectionStatus.connecting,
      errorMessage: null,
    );

    try {
      await _repository.initializeRenderer();

      _repository.onIceConnectionStateChange = (iceState) {
        switch (iceState) {
          case RTCIceConnectionState.RTCIceConnectionStateChecking:
            state = state.copyWith(status: ConnectionStatus.connecting);
            break;
          case RTCIceConnectionState.RTCIceConnectionStateConnected:
          case RTCIceConnectionState.RTCIceConnectionStateCompleted:
            state = state.copyWith(status: ConnectionStatus.connected);
            break;
          case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
            state = state.copyWith(status: ConnectionStatus.reconnecting);
            break;
          case RTCIceConnectionState.RTCIceConnectionStateFailed:
          case RTCIceConnectionState.RTCIceConnectionStateClosed:
            state = state.copyWith(status: ConnectionStatus.disconnected);
            break;
          default:
            break;
        }
      };

      _repository.onStatsUpdated = (latencyMs, fps, bitrateKbps) {
        state = state.copyWith(
          latencyMs: latencyMs,
          fps: fps,
          bitrateKbps: bitrateKbps,
        );
      };

      final settings = _ref.read(settingsProvider);
      await _repository.joinSession(
        hostIpAddress: cleanTarget,
        turnUrl: settings.turnUrl,
        turnUsername: settings.turnUsername,
        turnCredential: settings.turnCredential,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: 'Failed to connect to Host at $cleanTarget: ${e.toString()}',
      );
    }
  }

  void toggleTouchControl(bool enabled) {
    state = state.copyWith(isTouchControlActive: enabled);
  }

  void sendTap(double x, double y) => _repository.sendTap(x, y);
  void sendDoubleTap(double x, double y) => _repository.sendDoubleTap(x, y);
  void sendLongPress(double x, double y) => _repository.sendLongPress(x, y);
  void sendSwipe({
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    int durationMs = 300,
  }) {
    _repository.sendSwipe(
      startXPercent: startX,
      startYPercent: startY,
      endXPercent: endX,
      endYPercent: endY,
      durationMs: durationMs,
    );
  }

  void sendGlobalAction(String action) => _repository.sendGlobalAction(action);

  Future<void> leaveSession() async {
    await _repository.disposeViewerSession();
    state = ViewerSessionState.initial();
  }

  @override
  void dispose() {
    _repository.disposeViewerSession();
    super.dispose();
  }
}

final viewerProvider = StateNotifierProvider<ViewerNotifier, ViewerSessionState>((ref) {
  final repository = ref.watch(viewerWebRtcRepositoryProvider);
  return ViewerNotifier(repository, ref);
});
