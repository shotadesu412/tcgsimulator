import 'package:hive_ce/hive.dart';

// T05: Hiveスキーマ — GameState (手書きアダプター)

enum GameMode { solo, versus }

class GameStateModel extends HiveObject {
  late String id;
  late String presetId;
  late GameMode mode;
  late int turn;
  late DateTime updatedAt;
  List<PlayerStateEmbed> players = [];
  // v2: deckIdでゲームを識別（後方互換）
  String deckId = '';
}

class PlayerStateEmbed {
  PlayerStateEmbed({required this.playerId, required this.zonesJson});
  late String playerId;
  late String zonesJson;
}

class GameStateModelAdapter extends TypeAdapter<GameStateModel> {
  @override
  final int typeId = 3;

  @override
  GameStateModel read(BinaryReader reader) {
    final playerCount = reader.readInt();
    final players = List.generate(playerCount, (_) {
      return PlayerStateEmbed(
        playerId: reader.readString(),
        zonesJson: reader.readString(),
      );
    });
    final id = reader.readString();
    final presetId = reader.readString();
    final mode = GameMode.values[reader.readByte()];
    final turn = reader.readInt();
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    var deckId = '';
    try {
      deckId = reader.readString();
    } catch (_) {}
    return GameStateModel()
      ..id = id
      ..presetId = presetId
      ..mode = mode
      ..turn = turn
      ..updatedAt = updatedAt
      ..players = players
      ..deckId = deckId;
  }

  @override
  void write(BinaryWriter writer, GameStateModel obj) {
    writer.writeInt(obj.players.length);
    for (final p in obj.players) {
      writer.writeString(p.playerId);
      writer.writeString(p.zonesJson);
    }
    writer.writeString(obj.id);
    writer.writeString(obj.presetId);
    writer.writeByte(obj.mode.index);
    writer.writeInt(obj.turn);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeString(obj.deckId);
  }
}
