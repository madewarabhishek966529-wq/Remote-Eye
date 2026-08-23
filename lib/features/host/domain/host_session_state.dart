import '../../../core/widgets/status_badge.dart';

class HostSessionState {
  final String hostIp;
  final String sessionCode;
  final String qrData;
  final ConnectionStatus status;
  final bool isScreenCapturing;
  final bool isRemoteControlAllowed;
  final String? errorMessage;

  const HostSessionState({
    required this.hostIp,
    required this.sessionCode,
    required this.qrData,
    required this.status,
    required this.isScreenCapturing,
    required this.isRemoteControlAllowed,
    this.errorMessage,
  });

  factory HostSessionState.initial() {
    return const HostSessionState(
      hostIp: '',
      sessionCode: '',
      qrData: '',
      status: ConnectionStatus.idle,
      isScreenCapturing: false,
      isRemoteControlAllowed: false,
    );
  }

  HostSessionState copyWith({
    String? hostIp,
    String? sessionCode,
    String? qrData,
    ConnectionStatus? status,
    bool? isScreenCapturing,
    bool? isRemoteControlAllowed,
    String? errorMessage,
  }) {
    return HostSessionState(
      hostIp: hostIp ?? this.hostIp,
      sessionCode: sessionCode ?? this.sessionCode,
      qrData: qrData ?? this.qrData,
      status: status ?? this.status,
      isScreenCapturing: isScreenCapturing ?? this.isScreenCapturing,
      isRemoteControlAllowed: isRemoteControlAllowed ?? this.isRemoteControlAllowed,
      errorMessage: errorMessage,
    );
  }
}
