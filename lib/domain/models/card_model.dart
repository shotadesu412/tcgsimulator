import 'dart:ui' show Color;

import 'package:hive_ce/hive.dart';

// T05: Hiveスキーマ — Card (手書きアダプター)

const kCivilizations = ['光', '水', '闇', '火', '自然'];

const kCivColors = <String, Color>{
  '光': Color(0xFFFFD600),
  '水': Color(0xFF1E88E5),
  '闇': Color(0xFF7B1FA2),
  '火': Color(0xFFE53935),
  '自然': Color(0xFF43A047),
};

class CardModel extends HiveObject {
  late String id;
  late String name;
  late String imagePath;
  late DateTime createdAt;
  List<String> tags = [];
  // v2 fields (backwards-compat, default empty/0)
  String civilization = ''; // comma-joined e.g. "光,火"
  int cost = 0;
  String cardText = '';
  // v3 fields
  String backImagePath = ''; // 両面カード裏面 (空 = 通常カード)

  List<String> get civList =>
      civilization.isEmpty ? [] : civilization.split(',');
}

class CardModelAdapter extends TypeAdapter<CardModel> {
  @override
  final int typeId = 0;

  @override
  CardModel read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final imagePath = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final tags = reader.readStringList();
    // v2: new fields — wrapped in try-catch for old data
    var civilization = '';
    var cost = 0;
    var cardText = '';
    var backImagePath = '';
    try {
      civilization = reader.readString();
      cost = reader.readInt();
      cardText = reader.readString();
      backImagePath = reader.readString();
    } catch (_) {}
    return CardModel()
      ..id = id
      ..name = name
      ..imagePath = imagePath
      ..createdAt = createdAt
      ..tags = tags
      ..civilization = civilization
      ..cost = cost
      ..cardText = cardText
      ..backImagePath = backImagePath;
  }

  @override
  void write(BinaryWriter writer, CardModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.imagePath);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeStringList(obj.tags);
    writer.writeString(obj.civilization);
    writer.writeInt(obj.cost);
    writer.writeString(obj.cardText);
    writer.writeString(obj.backImagePath);
  }
}
