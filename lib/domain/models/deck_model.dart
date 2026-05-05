import 'package:hive_ce/hive.dart';

// T05: Hiveスキーマ — Deck (手書きアダプター)

class DeckModel extends HiveObject {
  late String id;
  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;
  List<DeckEntry> entries = [];
  // v2: 超次元ゾーン設定 (最大8枚, ゲーム開始時に超次元ゾーンへ配置)
  List<DeckEntry> hyperEntries = [];
}

class DeckEntry {
  DeckEntry({required this.cardId, this.count = 1});
  late String cardId;
  int count;
}

class DeckModelAdapter extends TypeAdapter<DeckModel> {
  @override
  final int typeId = 1;

  @override
  DeckModel read(BinaryReader reader) {
    final entryCount = reader.readInt();
    final entries = List.generate(entryCount, (_) {
      return DeckEntry(
        cardId: reader.readString(),
        count: reader.readInt(),
      );
    });
    final id = reader.readString();
    final name = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    // v2: 超次元エントリ (後方互換)
    var hyperEntries = <DeckEntry>[];
    try {
      final hyperCount = reader.readInt();
      hyperEntries = List.generate(hyperCount, (_) {
        return DeckEntry(
          cardId: reader.readString(),
          count: reader.readInt(),
        );
      });
    } catch (_) {}
    return DeckModel()
      ..id = id
      ..name = name
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..entries = entries
      ..hyperEntries = hyperEntries;
  }

  @override
  void write(BinaryWriter writer, DeckModel obj) {
    writer.writeInt(obj.entries.length);
    for (final e in obj.entries) {
      writer.writeString(e.cardId);
      writer.writeInt(e.count);
    }
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    // v2: 超次元エントリ
    writer.writeInt(obj.hyperEntries.length);
    for (final e in obj.hyperEntries) {
      writer.writeString(e.cardId);
      writer.writeInt(e.count);
    }
  }
}
