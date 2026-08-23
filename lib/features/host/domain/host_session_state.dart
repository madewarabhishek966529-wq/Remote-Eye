import '../../../core/widgets/status_badge.dart';

class HostSessionState {
  final String sessionCode;
  final ConnectionStatus status;
  final bool isScreenCapturing;
  final bool isRemoteControlAllowed;
  final String? errorMessage;

  const HostSessionState({
    required this.sessionCode,
    required this.status,
    required this.isScreenCapturing,
    required this.isRemoteControlAllowed,
    this.errorMessage,
  });

  factory HostSessionState.initial() {
    return const HostSessionState(
      sessionCode: '',
      status: ConnectionStatus.idle,
      isScreenCapturing: false,
      isRemoteControlAllowed: false,
    );
  }

  HostSessionState copyWith({
    String? sessionCode,
    ConnectionStatus? status,
    bool? isScreenCapturing,
    bool? isRemoteControlAllowed,
    String? errorMessage,
  }) {
    return HostSessionState(
      sessionCode: sessionCode ?? this.sessionCode,
      status: status ?? this.status,
      isScreenCapturing: isScreenCapturing ?? this.isScreenCapturing,
      isRemoteControlAllowed: isRemoteControlAllowed ?? this.isRemoteControlAllowed,
      errorMessage: errorMessage,
    );
  }
}
