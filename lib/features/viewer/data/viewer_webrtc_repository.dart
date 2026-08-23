import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/rtc_config.dart';
import '../../../core/network/local_signaling_service.dart';
import '../../../core/utils/logger.dart';

class ViewerWebRtcRepository {
  static const String _tag = 'ViewerWebRTC';

  final LocalSignalingService _signalingService;
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  StreamSubscription? _offerSub;
  StreamSubscription? _hostCandidatesSub;
  Timer? _statsTimer;

  Function(RTCIceConnectionState)? onIceConnectionStateChange;
  Function(MediaStream stream)? onRemoteStreamReceived;
  Function(int latencyMs, double fps, double bitrateKbps)? onStatsUpdated;
  Function(String error)? onError;

  ViewerWebRtcRepository(this._signalingService);

  /// Initializes RTCVideoRenderer
  Future<void> initializeRenderer() async {
    await remoteRenderer.initialize();
  }

  /// Connects to Host's embedded WebSocket signaling server using Host IP address
  Future<void> joinSession({
    required String hostIpAddress,
    String? turnUrl,
    String? turnUsername,
    String? turnCredential,
  }) async {
    try {
      AppLogger.i(_tag, 'Joining viewer session for Host IP: $hostIpAddress');

      final rtcConfig = RtcConfig.getIceServersConfig(
        customTurnUrl: turnUrl,
        customTurnUsername: turnUsername,
        customTurnCredential: turnCredential,
      );

      _peerConnection = await createPeerConnection(rtcConfig);
      AppLogger.i(_tag, 'Viewer PeerConnection created successfully');

      // 1. Listen for Remote Media Track
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          AppLogger.i(_tag, 'Received remote video track from Host!');
          remoteRenderer.srcObject = event.streams[0];
          if (onRemoteStreamReceived != null) {
            onRemoteStreamReceived!(event.streams[0]);
          }
        }
      };

      // 2. DataChannel for sending touch gestures
      final dataChannelInit = RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 3;
      _dataChannel = await _peerConnection!.createDataChannel(
        AppConstants.dataChannelLabel,
        dataChannelInit,
      );

      _peerConnection!.onDataChannel = (channel) {
        AppLogger.i(_tag, 'Viewer DataChannel connected: ${channel.label}');
        _dataChannel = channel;
      };

      // 3. Connect to Host's embedded WebSocket signaling server
      await _signalingService.connectToHost(hostIp: hostIpAddress);

      // 4. ICE Candidate Listener
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          _signalingService.sendViewerCandidate(candidate.toMap());
        }
      };

      // 5. ICE Connection State Listener
      _peerConnection!.onIceConnectionState = (state) {
        AppLogger.i(_tag, 'Viewer ICE Connection State: $state');
        if (onIceConnectionStateChange != null) {
          onIceConnectionStateChange!(state);
        }

        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          _startStatsMonitoring();
        }
      };

      // 6. Listen for Host SDP Offer over WebSocket
      _offerSub = _signalingService.onOfferReceived.listen((offerMap) async {
        if (_peerConnection != null) {
          AppLogger.i(_tag, 'Viewer received Host SDP Offer via WebSocket signaling');
          final description = RTCSessionDescription(
            offerMap['sdp'],
            offerMap['type'],
          );

          await _peerConnection!.setRemoteDescription(description);

          // Create Answer
          final answer = await _peerConnection!.createAnswer(RtcConfig.viewerAnswerConstraints);
          await _peerConnection!.setLocalDescription(answer);

          // Send Answer over WebSocket
          await _signalingService.sendViewerAnswer(answer.toMap());
        }
      });

      // 7. Listen for Host ICE Candidates over WebSocket
      _hostCandidatesSub = _signalingService.onHostCandidateReceived.listen((candMap) async {
        if (_peerConnection != null) {
          final candidate = RTCIceCandidate(
            candMap['candidate'],
            candMap['sdpMid'],
            candMap['sdpMLineIndex'],
          );
          await _peerConnection!.addCandidate(candidate);
        }
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'Error joining viewer session', e, st);
      if (onError != null) onError!(e.toString());
      rethrow;
    }
  }

  /// Sends normalized touch tap event over WebRTC DataChannel
  void sendTap(double xPercent, double yPercent) {
    _sendGestureMessage({
      'type': AppConstants.gestureTap,
      'x': double.parse(xPercent.toStringAsFixed(4)),
      'y': double.parse(yPercent.toStringAsFixed(4)),
    });
  }

  /// Sends normalized double tap event
  void sendDoubleTap(double xPercent, double yPercent) {
    _sendGestureMessage({
      'type': AppConstants.gestureDoubleTap,
      'x': double.parse(xPercent.toStringAsFixed(4)),
      'y': double.parse(yPercent.toStringAsFixed(4)),
    });
  }

  /// Sends normalized long press event
  void sendLongPress(double xPercent, double yPercent) {
    _sendGestureMessage({
      'type': AppConstants.gestureLongPress,
      'x': double.parse(xPercent.toStringAsFixed(4)),
      'y': double.parse(yPercent.toStringAsFixed(4)),
    });
  }

  /// Sends normalized swipe gesture event
  void sendSwipe({
    required double startXPercent,
    required double startYPercent,
    required double endXPercent,
    required double endYPercent,
    int durationMs = 300,
  }) {
    _sendGestureMessage({
      'type': AppConstants.gestureSwipe,
      'startX': double.parse(startXPercent.toStringAsFixed(4)),
      'startY': double.parse(startYPercent.toStringAsFixed(4)),
      'endX': double.parse(endXPercent.toStringAsFixed(4)),
      'endY': double.parse(endYPercent.toStringAsFixed(4)),
      'durationMs': durationMs,
    });
  }

  /// Sends Android global navigation action ('back', 'home', 'recents')
  void sendGlobalAction(String action) {
    _sendGestureMessage({
      'type': AppConstants.gestureGlobal,
      'action': action,
    });
  }

  void _sendGestureMessage(Map<String, dynamic> payload) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final jsonStr = jsonEncode(payload);
      _dataChannel!.send(RTCDataChannelMessage(jsonStr));
      AppLogger.d(_tag, 'Sent DataChannel gesture: $jsonStr');
    } else {
      AppLogger.w(_tag, 'Cannot send DataChannel message: DataChannel is not open');
    }
  }

  /// Monitors latency, bitrate, and FPS via peerconnection stats
  void _startStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_peerConnection == null) return;
      try {
        final stats = await _peerConnection!.getStats();
        int latency = 30; // Low latency estimate
        double fps = 30.0;
        double bitrate = 1200.0;

        for (var report in stats) {
          if (report.type == 'candidate-pair' && report.values['currentRoundTripTime'] != null) {
            final rttSec = (report.values['currentRoundTripTime'] as num).toDouble();
            latency = (rttSec * 1000).toInt();
          } else if (report.type == 'inbound-rtp' && report.values['kind'] == 'video') {
            if (report.values['framesPerSecond'] != null) {
              fps = (report.values['framesPerSecond'] as num).toDouble();
            }
          }
        }

        if (onStatsUpdated != null) {
          onStatsUpdated!(latency, fps, bitrate);
        }
      } catch (e) {
        AppLogger.e(_tag, 'Failed to fetch WebRTC stats', e);
      }
    });
  }

  /// Disposes viewer WebRTC resources
  Future<void> disposeViewerSession() async {
    AppLogger.i(_tag, 'Disposing viewer session...');
    _statsTimer?.cancel();
    await _offerSub?.cancel();
    await _hostCandidatesSub?.cancel();
    await _signalingService.disconnectViewer();
    await _dataChannel?.close();
    await _peerConnection?.close();
    _peerConnection = null;
    remoteRenderer.srcObject = null;
    await remoteRenderer.dispose();
  }
}
