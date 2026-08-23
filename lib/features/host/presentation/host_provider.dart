import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/network/local_signaling_service.dart';
import '../../../core/utils/code_generator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../settings/presentation/settings_provider.dart';
import '../data/host_webrtc_repository.dart';
import '../domain/host_session_state.dart';

final localSignalingProvider = Provider<LocalSignalingService>((ref) {
  final service = LocalSignalingService();
  ref.onDispose(() => service.dispose());
  return service;
});

final hostWebRtcRepositoryProvider = Provider<HostWebRtcRepository>((ref) {
  final signalingService = ref.watch(localSignalingProvider);
  return HostWebRtcRepository(signalingService);
});

class HostNotifier extends StateNotifier<HostSessionState> {
  final HostWebRtcRepository _repository;
  final Ref _ref;

  HostNotifier(this._repository, this._ref) : super(HostSessionState.initial());

  Future<void> prepareHostSession() async {
    final code = CodeGenerator.generateSessionCode();
    final allowControl = _ref.read(settingsProvider).allowRemoteControl;
    final localIp = await LocalSignalingService.getLocalIpAddress();
    final qrEndpoint = 'remoteeye://join/$localIp:8080';

    state = state.copyWith(
      hostIp: localIp,
      sessionCode: code,
      qrData: qrEndpoint,
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

      // 3. Initialize WebRTC peer connection & embedded signaling server
      final settings = _ref.read(settingsProvider);
      await _repository.initializeHostSession(
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
    await _repository.disposeHostSession();
    state = HostSessionState.initial();
  }

  @override
  void dispose() {
    _repository.disposeHostSession();
    super.dispose();
  }
}

final hostProvider = StateNotifierProvider<HostNotifier, HostSessionState>((ref) {
  final repository = ref.watch(hostWebRtcRepositoryProvider);
  return HostNotifier(repository, ref);
});
