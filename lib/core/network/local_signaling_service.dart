import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../utils/logger.dart';

class LocalSignalingService {
  static const String _tag = 'LocalSignaling';
  static const int defaultPort = 8080;

  // Host Server Side
  HttpServer? _hostServer;
  WebSocket? _hostWebSocket;

  // Viewer Client Side
  WebSocket? _viewerWebSocket;

  // Broadcast Controllers for Host
  final StreamController<Map<String, dynamic>> _answerController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _viewerCandidatesController = StreamController.broadcast();

  // Broadcast Controllers for Viewer
  final StreamController<Map<String, dynamic>> _offerController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _hostCandidatesController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get onAnswerReceived => _answerController.stream;
  Stream<Map<String, dynamic>> get onViewerCandidateReceived => _viewerCandidatesController.stream;

  Stream<Map<String, dynamic>> get onOfferReceived => _offerController.stream;
  Stream<Map<String, dynamic>> get onHostCandidateReceived => _hostCandidatesController.stream;

  /// Retrieves local IPv4 address of this device (Wi-Fi or Mobile Hotspot)
  static Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        // Exclude loopback interface
        if (interface.name.contains('lo') || interface.name.contains('Loopback')) continue;
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            AppLogger.i(_tag, 'Found local IP address: ${addr.address} on interface ${interface.name}');
            return addr.address;
          }
        }
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to resolve local IP address', e, st);
    }
    return '127.0.0.1';
  }

  // ================= HOST SERVER METHODS =================

  /// Starts embedded WebSocket signaling server on Host phone
  Future<void> startHostServer({int port = defaultPort}) async {
    try {
      await closeHostServer();
      _hostServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
      AppLogger.i(_tag, 'Embedded Host signaling server listening on port $port');

      _hostServer!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          _hostWebSocket = await WebSocketTransformer.upgrade(request);
          AppLogger.i(_tag, 'Viewer connected to Host embedded signaling server');

          _hostWebSocket!.listen((message) {
            _handleHostIncomingMessage(message.toString());
          }, onDone: () {
            AppLogger.i(_tag, 'Viewer disconnected from Host signaling server');
          }, onError: (e) {
            AppLogger.e(_tag, 'Host WebSocket error', e);
          });
        } else {
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
        }
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to start Host embedded signaling server', e, st);
      rethrow;
    }
  }

  void _handleHostIncomingMessage(String rawMessage) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawMessage);
      final String type = data['type'] ?? '';

      if (type == 'answer') {
        AppLogger.i(_tag, 'Host received SDP Answer from Viewer');
        _answerController.add(data['sdpData']);
      } else if (type == 'viewer_candidate') {
        AppLogger.d(_tag, 'Host received Viewer ICE candidate');
        _viewerCandidatesController.add(data['candidateData']);
      }
    } catch (e) {
      AppLogger.e(_tag, 'Error handling Host incoming signaling message', e);
    }
  }

  /// Sends Host's SDP Offer to connected Viewer over WebSocket
  Future<void> sendHostOffer(Map<String, dynamic> offerData) async {
    if (_hostWebSocket != null && _hostWebSocket!.readyState == WebSocket.open) {
      _hostWebSocket!.add(jsonEncode({
        'type': 'offer',
        'sdpData': offerData,
      }));
      AppLogger.i(_tag, 'Host sent SDP Offer to Viewer over WebSocket');
    }
  }

  /// Sends Host's ICE Candidate to connected Viewer over WebSocket
  Future<void> sendHostCandidate(Map<String, dynamic> candidateData) async {
    if (_hostWebSocket != null && _hostWebSocket!.readyState == WebSocket.open) {
      _hostWebSocket!.add(jsonEncode({
        'type': 'host_candidate',
        'candidateData': candidateData,
      }));
    }
  }

  /// Closes Host embedded WebSocket server
  Future<void> closeHostServer() async {
    await _hostWebSocket?.close();
    _hostWebSocket = null;
    await _hostServer?.close(force: true);
    _hostServer = null;
    AppLogger.i(_tag, 'Host embedded signaling server closed');
  }

  // ================= VIEWER CLIENT METHODS =================

  /// Connects Viewer to Host's embedded WebSocket signaling server
  Future<void> connectToHost({required String hostIp, int port = defaultPort}) async {
    try {
      await disconnectViewer();
      final wsUrl = 'ws://$hostIp:$port';
      AppLogger.i(_tag, 'Viewer connecting to Host signaling WebSocket at $wsUrl');

      _viewerWebSocket = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 8));
      AppLogger.i(_tag, 'Viewer connected to Host signaling server successfully');

      _viewerWebSocket!.listen((message) {
        _handleViewerIncomingMessage(message.toString());
      }, onDone: () {
        AppLogger.i(_tag, 'Viewer WebSocket connection closed');
      }, onError: (e) {
        AppLogger.e(_tag, 'Viewer WebSocket error', e);
      });
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to connect to Host signaling server at $hostIp', e, st);
      rethrow;
    }
  }

  void _handleViewerIncomingMessage(String rawMessage) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawMessage);
      final String type = data['type'] ?? '';

      if (type == 'offer') {
        AppLogger.i(_tag, 'Viewer received SDP Offer from Host');
        _offerController.add(data['sdpData']);
      } else if (type == 'host_candidate') {
        AppLogger.d(_tag, 'Viewer received Host ICE candidate');
        _hostCandidatesController.add(data['candidateData']);
      }
    } catch (e) {
      AppLogger.e(_tag, 'Error handling Viewer incoming signaling message', e);
    }
  }

  /// Sends Viewer's SDP Answer to Host over WebSocket
  Future<void> sendViewerAnswer(Map<String, dynamic> answerData) async {
    if (_viewerWebSocket != null && _viewerWebSocket!.readyState == WebSocket.open) {
      _viewerWebSocket!.add(jsonEncode({
        'type': 'answer',
        'sdpData': answerData,
      }));
      AppLogger.i(_tag, 'Viewer sent SDP Answer to Host over WebSocket');
    }
  }

  /// Sends Viewer's ICE Candidate to Host over WebSocket
  Future<void> sendViewerCandidate(Map<String, dynamic> candidateData) async {
    if (_viewerWebSocket != null && _viewerWebSocket!.readyState == WebSocket.open) {
      _viewerWebSocket!.add(jsonEncode({
        'type': 'viewer_candidate',
        'candidateData': candidateData,
      }));
    }
  }

  /// Disconnects Viewer WebSocket client
  Future<void> disconnectViewer() async {
    await _viewerWebSocket?.close();
    _viewerWebSocket = null;
    AppLogger.i(_tag, 'Viewer signaling client disconnected');
  }

  void dispose() {
    _answerController.close();
    _viewerCandidatesController.close();
    _offerController.close();
    _hostCandidatesController.close();
    closeHostServer();
    disconnectViewer();
  }
}
