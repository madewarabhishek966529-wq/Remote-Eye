/// WebRTC PeerConnection & ICE Server Configuration for RemoteEye.
///
/// STUN servers enable peer-to-peer discovery across simple NATs.
/// TURN servers act as relay fallbacks when strict symmetric NATs or firewalls block direct P2P connection.
class RtcConfig {
  /// Default ICE Servers configuration including STUN and TURN placeholders.
  static Map<String, dynamic> getIceServersConfig({
    String? customTurnUrl,
    String? customTurnUsername,
    String? customTurnCredential,
  }) {
    final List<Map<String, dynamic>> iceServers = [
      // Free public STUN server provided by Google
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ];

    // TURN Configuration (Relay server for strict NATs)
    // Replace with your real TURN credentials (e.g. Coturn, Metered.ca, Twilio, or Xirsys)
    final turnUrl = customTurnUrl ?? 'turn:relay.metered.ca:443';
    final turnUsername = customTurnUsername ?? 'open_source_user';
    final turnCredential = customTurnCredential ?? 'open_source_pass';

    iceServers.add({
      'urls': turnUrl,
      'username': turnUsername,
      'credential': turnCredential,
    });

    return {
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all', // 'all' allows direct STUN P2P + TURN relay fallback
    };
  }

  /// SDP constraints for media stream negotiation
  static Map<String, dynamic> get hostOfferConstraints => {
        'mandatory': {
          'OfferToReceiveAudio': false,
          'OfferToReceiveVideo': false,
        },
        'optional': [],
      };

  static Map<String, dynamic> get viewerAnswerConstraints => {
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': true,
        },
        'optional': [],
      };

  /// Data Channel Configuration for Touch Control
  static Map<String, dynamic> get dataChannelConfig => {
        'ordered': true,
        'maxRetransmits': 3,
      };
}
