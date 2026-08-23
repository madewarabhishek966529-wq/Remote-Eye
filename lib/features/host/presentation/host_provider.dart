import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/network/firebase_signaling_service.dart';
import '../../../core/utils/code_generator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../settings/presentation/settings_provider.dart';
import '../data/host_webrtc_repository.dart';
import '../domain/host_session_state.dart';

final firebaseSignalingProvider = Provider<FirebaseSignalingService>((ref) {
  return FirebaseSignalingService();
});

final hostWebRtcRepositoryProvider = Provider<HostWebRtcRepository>((ref) {
  final signalingService = ref.watch(firebaseSignalingProvider);
  return HostWebRtcRepository(signalingService);
});

class HostNotifier extends StateNotifier<HostSessionState> {
  final HostWebRtcRepository _repository;
  final Ref _ref;

  HostNotifier(this._repository, this._ref) : super(HostSessionState.initial());

  Future<void> prepareHostSession() async {
    final code = CodeGenerator.generateSessionCode();
    final allowControl = _ref.read(settingsProvider).allowRemoteControl;

    state = state.copyWith(
      sessionCode: code,
      status: ConnectionStatus.creating,
      isRemoteControlAllowed: allowControl,
    );

    try {
      // 1. Request MediaProjection screen capture permission
      await _repository.startScreenCapture();
      state = state.copyWith(
        isScreenCapturing: true,
        status: ConnectionStatus.waitingForViewer,
      );

      // 2. Setup ICE connection state callback
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

      // 3. Initialize WebRTC peer connection & signaling
      final settings = _ref.read(settingsProvider);
      await _repository.initializeHostSession(
        sessionCode: code,
        allowRemoteControl: allowControl,
        turnUrl: settings.turnUrl,
        turnUsername: settings.turnUsername,
        turnCredential: settings.turnCredential,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void updateAllowRemoteControl(bool value) {
    state = state.copyWith(isRemoteControlAllowed: value);
    _ref.read(settingsProvider.notifier).toggleAllowRemoteControl(value);
  }

  Future<void> endSession() async {
    await _repository.disposeHostSession(state.sessionCode);
    state = HostSessionState.initial();
  }

  @override
  void dispose() {
    _repository.disposeHostSession(state.sessionCode);
    super.dispose();
  }
}

final hostProvider = StateNotifierProvider<HostNotifier, HostSessionState>((ref) {
  final repository = ref.watch(hostWebRtcRepositoryProvider);
  return HostNotifier(repository, ref);
});
