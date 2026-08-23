import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/rtc_config.dart';
import '../../../core/network/local_signaling_service.dart';
import '../../../core/utils/logger.dart';
import '../../accessibility/data/accessibility_native_service.dart';

class HostWebRtcRepository {
  static const String _tag = 'HostWebRTC';

  final LocalSignalingService _signalingService;
  final AccessibilityNativeService _accessibilityService = AccessibilityNativeService();

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localDisplayStream;

  StreamSubscription? _answerSub;
  StreamSubscription? _viewerCandidatesSub;

  Function(RTCIceConnectionState)? onIceConnectionStateChange;
  Function(String error)? onError;

  HostWebRtcRepository(this._signalingService);

  MediaStream? get localDisplayStream => _localDisplayStream;

  /// Starts Android MediaProjection screen capture using flutter_webrtc
  Future<MediaStream> startScreenCapture() async {
    try {
      AppLogger.i(_tag, 'Requesting Android MediaProjection display media...');
      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': '720',
            'minHeight': '1280',
            'minFrameRate': '30',
          },
          'optional': [],
        }
      };

      _localDisplayStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      AppLogger.i(_tag, 'Screen capture started successfully. Stream ID: ${_localDisplayStream?.id}');
      return _localDisplayStream!;
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to start screen capture', e, st);
      throw Exception('Screen capture permission denied or failed: $e');
    }
  }

  /// Initializes RTCPeerConnection & embedded WebSocket signaling server
  Future<void> initializeHostSession({
    required bool allowRemoteControl,
    String? turnUrl,
    String? turnUsername,
    String? turnCredential,
  }) async {
    try {
      AppLogger.i(_tag, 'Initializing host WebRTC session with embedded local signaling server');

      // 1. Start embedded local WebSocket signaling server
      await _signalingService.startHostServer();

      // 2. Create RTCPeerConnection
      final rtcConfig = RtcConfig.getIceServersConfig(
        customTurnUrl: turnUrl,
        customTurnUsername: turnUsername,
        customTurnCredential: turnCredential,
      );

      _peerConnection = await createPeerConnection(rtcConfig);
      AppLogger.i(_tag, 'Host PeerConnection created successfully');

      // 3. Add Screen Capture tracks to PeerConnection
      if (_localDisplayStream != null) {
        for (var track in _localDisplayStream!.getTracks()) {
          await _peerConnection!.addTrack(track, _localDisplayStream!);
        }
      }

      // 4. Setup Data Channel for incoming touch events from viewer
      final dataChannelInit = RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 3;
      _dataChannel = await _peerConnection!.createDataChannel(
        AppConstants.dataChannelLabel,
        dataChannelInit,
      );
      _setupDataChannelListeners(allowRemoteControl);

      // Also listen if viewer initiates data channel
      _peerConnection!.onDataChannel = (channel) {
        AppLogger.i(_tag, 'DataChannel received from Viewer: ${channel.label}');
        _dataChannel = channel;
        _setupDataChannelListeners(allowRemoteControl);
      };

      // 5. ICE Candidate Listener
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          _signalingService.sendHostCandidate(candidate.toMap());
        }
      };

      // 6. ICE Connection State Listener
      _peerConnection!.onIceConnectionState = (state) {
        AppLogger.i(_tag, 'Host ICE Connection State: $state');
        if (onIceConnectionStateChange != null) {
          onIceConnectionStateChange!(state);
        }

        // Clean up embedded signaling server once P2P connection is established
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          AppLogger.i(_tag, 'P2P Connection Established! Closing embedded WebSocket signaling server...');
          _signalingService.closeHostServer();
        }
      };

      // 7. Create SDP Offer & set local description
      final offer = await _peerConnection!.createOffer(RtcConfig.hostOfferConstraints);
      await _peerConnection!.setLocalDescription(offer);

      // 8. Listen for Viewer SDP Answer
      _answerSub = _signalingService.onAnswerReceived.listen((answerMap) async {
        if (_peerConnection != null) {
          AppLogger.i(_tag, 'Host received Viewer Answer via WebSocket signaling');
          final description = RTCSessionDescription(
            answerMap['sdp'],
            answerMap['type'],
          );
          await _peerConnection!.setRemoteDescription(description);
        }
      });

      // 9. Listen for Viewer ICE Candidates
      _viewerCandidatesSub = _signalingService.onViewerCandidateReceived.listen((candMap) async {
        if (_peerConnection != null) {
          final candidate = RTCIceCandidate(
            candMap['candidate'],
            candMap['sdpMid'],
            candMap['sdpMLineIndex'],
          );
          await _peerConnection!.addCandidate(candidate);
        }
      });

      // 10. Send SDP Offer over embedded WebSocket
      await _signalingService.sendHostOffer(offer.toMap());
    } catch (e, st) {
      AppLogger.e(_tag, 'Error initializing host session', e, st);
      if (onError != null) onError!(e.toString());
      rethrow;
    }
  }

  /// Sets up listeners on the WebRTC DataChannel to parse and execute touch gestures
  void _setupDataChannelListeners(bool allowRemoteControl) {
    if (_dataChannel == null) return;

    _dataChannel!.onMessage = (RTCDataChannelMessage message) async {
      if (message.type != MessageType.text || message.text.isEmpty) return;

      AppLogger.d(_tag, 'Received DataChannel gesture payload: ${message.text}');

      if (!allowRemoteControl) {
        AppLogger.w(_tag, 'Remote control gesture ignored: Host security setting is OFF');
        return;
      }

      try {
        final Map<String, dynamic> data = jsonDecode(message.text);
        final String type = data['type'] ?? '';

        switch (type) {
          case AppConstants.gestureTap:
            final double x = (data['x'] as num).toDouble();
            final double y = (data['y'] as num).toDouble();
            await _accessibilityService.injectTap(x, y);
            break;

          case AppConstants.gestureDoubleTap:
            final double x = (data['x'] as num).toDouble();
            final double y = (data['y'] as num).toDouble();
            await _accessibilityService.injectDoubleTap(x, y);
            break;

          case AppConstants.gestureLongPress:
            final double x = (data['x'] as num).toDouble();
            final double y = (data['y'] as num).toDouble();
            await _accessibilityService.injectLongPress(x, y);
            break;

          case AppConstants.gestureSwipe:
            final double startX = (data['startX'] as num).toDouble();
            final double startY = (data['startY'] as num).toDouble();
            final double endX = (data['endX'] as num).toDouble();
            final double endY = (data['endY'] as num).toDouble();
            final int duration = data['durationMs'] ?? 300;
            await _accessibilityService.injectSwipe(
              startXPercent: startX,
              startYPercent: startY,
              endXPercent: endX,
              endYPercent: endY,
              durationMs: duration,
            );
            break;

          case AppConstants.gestureGlobal:
            final String action = data['action'] ?? '';
            await _accessibilityService.triggerGlobalAction(action);
            break;
        }
      } catch (e) {
        AppLogger.e(_tag, 'Failed to process DataChannel gesture payload', e);
      }
    };
  }

  /// Cleanly closes media streams, peer connections, and embedded signaling server
  Future<void> disposeHostSession() async {
    AppLogger.i(_tag, 'Disposing host session...');
    await _answerSub?.cancel();
    await _viewerCandidatesSub?.cancel();

    await _signalingService.closeHostServer();

    await _dataChannel?.close();
    await _peerConnection?.close();
    _peerConnection = null;

    if (_localDisplayStream != null) {
      for (var track in _localDisplayStream!.getTracks()) {
        await track.stop();
      }
      await _localDisplayStream!.dispose();
      _localDisplayStream = null;
    }
  }
}
