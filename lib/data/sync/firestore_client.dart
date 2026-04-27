import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger.dart';

// T22: Firebase初期化、Anonymous Auth、firestore_client (Phase 5)

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final anonymousUidProvider = FutureProvider<String>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth.currentUser != null) return auth.currentUser!.uid;

  final cred = await auth.signInAnonymously();
  AppLogger.i('Signed in anonymously: ${cred.user?.uid}');
  return cred.user!.uid;
});

class FirestoreClient {
  FirestoreClient(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  // rooms/{roomCode}/players/{uid}/publicState
  DocumentReference<Map<String, dynamic>> publicStateRef(String roomCode) {
    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('players')
        .doc(_uid)
        .collection('publicState')
        .doc('state');
  }

  DocumentReference<Map<String, dynamic>> privateStateRef(String roomCode) {
    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('players')
        .doc(_uid)
        .collection('privateState')
        .doc('state');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchPublicState(
    String roomCode,
    String opponentUid,
  ) {
    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('players')
        .doc(opponentUid)
        .collection('publicState')
        .doc('state')
        .snapshots();
  }

  Future<String> createRoom(String presetId) async {
    final code = _generateRoomCode();
    await _db.collection('rooms').doc(code).set({
      'createdAt': FieldValue.serverTimestamp(),
      'hostUid': _uid,
      'guestUid': null,
      'status': 'waiting',
      'presetId': presetId,
    });
    return code;
  }

  Future<bool> joinRoom(String roomCode) async {
    final ref = _db.collection('rooms').doc(roomCode);
    final snap = await ref.get();
    if (!snap.exists) return false;

    final data = snap.data()!;
    if (data['status'] != 'waiting') return false;

    await ref.update({'guestUid': _uid, 'status': 'playing'});
    return true;
  }

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    final now = DateTime.now().millisecondsSinceEpoch;
    var seed = now;
    for (var i = 0; i < 6; i++) {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      buffer.write(chars[seed % chars.length]);
    }
    return buffer.toString();
  }
}

final firestoreClientProvider = FutureProvider<FirestoreClient>((ref) async {
  final uid = await ref.watch(anonymousUidProvider.future);
  final db = ref.watch(firestoreProvider);
  return FirestoreClient(db, uid);
});
