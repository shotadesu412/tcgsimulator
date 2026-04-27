// T07: ZoneDef — ゾーン定義（データ駆動）

enum ZoneVisibility {
  private,          // 自分のみ見える（手札）
  public,           // 全員見える
  publicCountOnly,  // 枚数のみ公開（山札）
  publicBack,       // 裏面のみ公開（シールド）
}

enum ZoneLayout {
  stack,  // 重ね（山札・墓地）
  fan,    // 扇形（手札・マナ）
  grid,   // グリッド（シールド・超次元）
  free,   // 自由配置（バトルゾーン）
}

class ZoneDef {
  const ZoneDef({
    required this.key,
    required this.label,
    required this.visibility,
    required this.layout,
    required this.ordered,
    required this.faceDownByDefault,
  });

  final String key;
  final String label;
  final ZoneVisibility visibility;
  final ZoneLayout layout;
  final bool ordered;
  final bool faceDownByDefault;

  factory ZoneDef.fromJson(Map<String, dynamic> json) {
    return ZoneDef(
      key: json['key'] as String,
      label: json['label'] as String,
      visibility: ZoneVisibility.values.byName(
        _snakeToCamel(json['visibility'] as String),
      ),
      layout: ZoneLayout.values.byName(json['layout'] as String),
      ordered: json['ordered'] as bool,
      faceDownByDefault: json['faceDownByDefault'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'visibility': _camelToSnake(visibility.name),
    'layout': layout.name,
    'ordered': ordered,
    'faceDownByDefault': faceDownByDefault,
  };

  // "public_count_only" → "publicCountOnly"
  static String _snakeToCamel(String s) {
    return s.splitMapJoin(
      '_',
      onMatch: (_) => '',
      onNonMatch: (n) => n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1),
    ).replaceFirst(s[0].toUpperCase(), s[0].toLowerCase());
  }

  // "publicCountOnly" → "public_count_only"
  static String _camelToSnake(String s) {
    return s.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }
}

class GamePreset {
  const GamePreset({
    required this.id,
    required this.name,
    required this.zones,
    required this.initialHand,
  });

  final String id;
  final String name;
  final List<ZoneDef> zones;
  final int initialHand;

  factory GamePreset.fromJson(Map<String, dynamic> json) {
    return GamePreset(
      id: json['id'] as String,
      name: json['name'] as String,
      zones: (json['zones'] as List)
          .map((z) => ZoneDef.fromJson(z as Map<String, dynamic>))
          .toList(),
      initialHand: json['initialHand'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'zones': zones.map((z) => z.toJson()).toList(),
    'initialHand': initialHand,
  };
}

class CardInstance {
  CardInstance({
    required this.instanceId,
    required this.cardId,
    this.faceUp = true,
    this.tapped = false,
    this.counters = const {},
    this.position,
    this.stackId,
    this.stackIndex = 0,
  });

  final String instanceId;
  final String cardId;
  bool faceUp;
  bool tapped;
  Map<String, int> counters;
  ({double x, double y})? position;
  String? stackId;   // 同じstackIdのカードは重なって表示
  int stackIndex;    // スタック内の順番（0=一番下）

  CardInstance copyWith({
    bool? faceUp,
    bool? tapped,
    Map<String, int>? counters,
    ({double x, double y})? position,
    String? stackId,
    bool clearStack = false,
    int? stackIndex,
  }) {
    return CardInstance(
      instanceId: instanceId,
      cardId: cardId,
      faceUp: faceUp ?? this.faceUp,
      tapped: tapped ?? this.tapped,
      counters: counters ?? this.counters,
      position: position ?? this.position,
      stackId: clearStack ? null : (stackId ?? this.stackId),
      stackIndex: stackIndex ?? this.stackIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'cardId': cardId,
    'faceUp': faceUp,
    'tapped': tapped,
    'counters': counters,
    if (position != null) 'position': {'x': position!.x, 'y': position!.y},
    if (stackId != null) 'stackId': stackId,
    if (stackIndex != 0) 'stackIndex': stackIndex,
  };

  factory CardInstance.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>?;
    return CardInstance(
      instanceId: json['instanceId'] as String,
      cardId: json['cardId'] as String,
      faceUp: json['faceUp'] as bool? ?? true,
      tapped: json['tapped'] as bool? ?? false,
      counters: (json['counters'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as int)),
      position: pos != null
          ? (x: (pos['x'] as num).toDouble(), y: (pos['y'] as num).toDouble())
          : null,
      stackId: json['stackId'] as String?,
      stackIndex: json['stackIndex'] as int? ?? 0,
    );
  }
}
