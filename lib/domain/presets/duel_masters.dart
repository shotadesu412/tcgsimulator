import '../models/zone_def.dart';

// T07: デュエル・マスターズ風プリセット

const kDuelMastersPreset = GamePreset(
  id: 'duel_masters',
  name: 'デュエル・マスターズ風',
  initialHand: 5,
  zones: [
    ZoneDef(
      key: 'deck',
      label: '山札',
      visibility: ZoneVisibility.publicCountOnly,
      layout: ZoneLayout.stack,
      ordered: true,
      faceDownByDefault: true,
    ),
    ZoneDef(
      key: 'palette',
      label: 'パレット',
      visibility: ZoneVisibility.public,
      layout: ZoneLayout.fan,
      ordered: true,
      faceDownByDefault: false,
    ),
    ZoneDef(
      key: 'hand',
      label: '手札',
      visibility: ZoneVisibility.private,
      layout: ZoneLayout.fan,
      ordered: false,
      faceDownByDefault: false,
    ),
    ZoneDef(
      key: 'shield',
      label: 'シールド',
      visibility: ZoneVisibility.publicBack,
      layout: ZoneLayout.grid,
      ordered: false,
      faceDownByDefault: true,
    ),
    ZoneDef(
      key: 'battle',
      label: 'バトルゾーン',
      visibility: ZoneVisibility.public,
      layout: ZoneLayout.free,
      ordered: false,
      faceDownByDefault: false,
    ),
    ZoneDef(
      key: 'mana',
      label: 'マナゾーン',
      visibility: ZoneVisibility.public,
      layout: ZoneLayout.fan,
      ordered: false,
      faceDownByDefault: false,
    ),
    ZoneDef(
      key: 'graveyard',
      label: '墓地',
      visibility: ZoneVisibility.public,
      layout: ZoneLayout.stack,
      ordered: false,
      faceDownByDefault: false,
    ),
    ZoneDef(
      key: 'hyper',
      label: '超次元ゾーン',
      visibility: ZoneVisibility.public,
      layout: ZoneLayout.grid,
      ordered: false,
      faceDownByDefault: false,
    ),
  ],
);

const kAllPresets = [kDuelMastersPreset];
