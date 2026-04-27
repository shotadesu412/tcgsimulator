import 'package:hive_ce/hive.dart';

// T05: Hiveスキーマ — Deck (手書きアダプター)

class DeckModel extends HiveObject {
  late String id;
  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;
  List<DeckEntry> entries = [];
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
    return DeckModel()
      ..id = reader.readString()
      ..name = reader.readString()
      ..createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt())
      ..updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt())
      ..entries = entries;
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
  }
}
