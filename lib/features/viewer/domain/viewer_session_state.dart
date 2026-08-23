import '../../../core/widgets/status_badge.dart';

class ViewerSessionState {
  final String sessionCode;
  final ConnectionStatus status;
  final int latencyMs;
  final double fps;
  final double bitrateKbps;
  final bool isTouchControlActive;
  final String? errorMessage;

  const ViewerSessionState({
    required this.sessionCode,
    required this.status,
    this.latencyMs = 0,
    this.fps = 0.0,
    this.bitrateKbps = 0.0,
    this.isTouchControlActive = true,
    this.errorMessage,
  });

  factory ViewerSessionState.initial() {
    return const ViewerSessionState(
      sessionCode: '',
      status: ConnectionStatus.idle,
    );
  }

  ViewerSessionState copyWith({
    String? sessionCode,
    ConnectionStatus? status,
    int? latencyMs,
    double? fps,
    double? bitrateKbps,
    bool? isTouchControlActive,
    String? errorMessage,
  }) {
    return ViewerSessionState(
      sessionCode: sessionCode ?? this.sessionCode,
      status: status ?? this.status,
      latencyMs: latencyMs ?? this.latencyMs,
      fps: fps ?? this.fps,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      isTouchControlActive: isTouchControlActive ?? this.isTouchControlActive,
      errorMessage: errorMessage,
    );
  }
}
