// T22-T25: Room Repository (Phase 5 stub)
// Firestore同期の実装はPhase 5で行う。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/zone_def.dart';
import 'firestore_client.dart';

class RoomRepository {
  RoomRepository(this._client);

  final FirestoreClient _client;

  Future<String> createRoom(String presetId) => _client.createRoom(presetId);
  Future<bool> joinRoom(String roomCode) => _client.joinRoom(roomCode);

  Future<void> updatePublicState(
    String roomCode,
    Map<String, List<CardInstance>> publicZones,
    int deckCount,
    int handCount,
  ) async {
    final state = {
      'zones': {
        for (final e in publicZones.entries)
          e.key: e.value.map((c) => c.toJson()).toList(),
      },
      'deckCount': deckCount,
      'handCount': handCount,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _client.publicStateRef(roomCode).set(state);
  }
}

final roomRepositoryProvider = FutureProvider<RoomRepository>((ref) async {
  final client = await ref.watch(firestoreClientProvider.future);
  return RoomRepository(client);
});
