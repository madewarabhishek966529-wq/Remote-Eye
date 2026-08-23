import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class FirebaseSignalingService {
  static const String _tag = 'FirebaseSignaling';
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Creates a new session node in Realtime Database under `/sessions/{code}`
  Future<void> createSession(String code) async {
    try {
      final ref = _db.ref('${AppConstants.sessionsPath}/$code');
      await ref.set({
        'createdAt': ServerValue.timestamp,
        'status': 'waiting',
      });
      AppLogger.i(_tag, 'Session created: $code');
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to create session $code', e, st);
      rethrow;
    }
  }

  /// Writes Host's SDP Offer to Firebase
  Future<void> setHostOffer(String code, Map<String, dynamic> offer) async {
    try {
      final ref = _db.ref('${AppConstants.sessionsPath}/$code/offer');
      await ref.set(offer);
      AppLogger.i(_tag, 'Host offer set for session: $code');
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to set host offer', e, st);
      rethrow;
    }
  }

  /// Listens for Host's SDP Offer (used by Viewer)
  Stream<Map<String, dynamic>?> listenForOffer(String code) {
    final ref = _db.ref('${AppConstants.sessionsPath}/$code/offer');
    return ref.onValue.map((event) {
      if (event.snapshot.value != null) {
        final rawMap = event.snapshot.value as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(rawMap);
      }
      return null;
    });
  }

  /// Writes Viewer's SDP Answer to Firebase
  Future<void> setViewerAnswer(String code, Map<String, dynamic> answer) async {
    try {
      final ref = _db.ref('${AppConstants.sessionsPath}/$code/answer');
      await ref.set(answer);
      await _db.ref('${AppConstants.sessionsPath}/$code/status').set('connected');
      AppLogger.i(_tag, 'Viewer answer set for session: $code');
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to set viewer answer', e, st);
      rethrow;
    }
  }

  /// Listens for Viewer's SDP Answer (used by Host)
  Stream<Map<String, dynamic>?> listenForAnswer(String code) {
    final ref = _db.ref('${AppConstants.sessionsPath}/$code/answer');
    return ref.onValue.map((event) {
      if (event.snapshot.value != null) {
        final rawMap = event.snapshot.value as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(rawMap);
      }
      return null;
    });
  }

  /// Adds a Host ICE Candidate to Firebase
  Future<void> addHostCandidate(String code, Map<String, dynamic> candidate) async {
    try {
      final ref = _db.ref('${AppConstants.sessionsPath}/$code/hostCandidates').push();
      await ref.set(candidate);
      AppLogger.d(_tag, 'Host ICE candidate added to Firebase');
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to add host candidate', e, st);
    }
  }

  /// Listens for Host ICE Candidates (used by Viewer)
  Stream<Map<String, dynamic>> listenForHostCandidates(String code) {
    final ref = _db.ref('${AppConstants.sessionsPath}/$code/hostCandidates');
    return ref.onChildAdded.map((event) {
      final rawMap = event.snapshot.value as Map<dynamic, dynamic>;
      return Map<String, dynamic>.from(rawMap);
    });
  }

  /// Adds a Viewer ICE Candidate to Firebase
  Future<void> addViewerCandidate(String code, Map<String, dynamic> candidate) async {
    try {
      final ref = _db.ref('${AppConstants.sessionsPath}/$code/viewerCandidates').push();
      await ref.set(candidate);
      AppLogger.d(_tag, 'Viewer ICE candidate added to Firebase');
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to add viewer candidate', e, st);
    }
  }

  /// Listens for Viewer ICE Candidates (used by Host)
  Stream<Map<String, dynamic>> listenForViewerCandidates(String code) {
    final ref = _db.ref('${AppConstants.sessionsPath}/$code/viewerCandidates');
    return ref.onChildAdded.map((event) {
      final rawMap = event.snapshot.value as Map<dynamic, dynamic>;
      return Map<String, dynamic>.from(rawMap);
    });
  }

  /// Cleans up session node from Firebase Realtime Database
  Future<void> deleteSession(String code) async {
    try {
      final ref = _db.ref('${AppConstants.sessionsPath}/$code');
      await ref.remove();
      AppLogger.i(_tag, 'Session node deleted from Firebase: $code');
    } catch (e, st) {
      AppLogger.e(_tag, 'Failed to delete session $code', e, st);
    }
  }
}
