# BoardKit セットアップ手順

## 1. 前提条件

```bash
flutter --version   # 3.x 以上
dart --version      # 3.x 以上
```

Flutter未インストールの場合: https://flutter.dev/docs/get-started/install

## 2. 依存パッケージ取得

```bash
cd C:\tcgsimulator
flutter pub get
```

## 3. コード生成 (Isar スキーマ)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 4. Firebase セットアップ (Phase 5で必要)

```bash
# FlutterFireCLIをインストール
dart pub global activate flutterfire_cli

# Firebaseプロジェクト作成後
flutterfire configure
```

`lib/firebase_options.dart` が自動生成されます。

## 5. ビルド & 実行

```bash
# デバッグ実行
flutter run

# Androidリリースビルド
flutter build apk --release

# iOSリリースビルド (Mac必須)
flutter build ios --release

# Webビルド
flutter build web --release
```

## 実装済みタスク (Phase 0-3 主要部分)

| タスク | 状態 |
|--------|------|
| T01 プロジェクト初期化・pubspec.yaml | ✅ |
| T02 ライト/ダークテーマ | ✅ |
| T03 core/ (id, Result, Logger) | ✅ |
| T04 ルーティング雛形 (S01-S11) | ✅ |
| T05 Isarスキーマ + DAO | ✅ |
| T06 ローカル画像ストレージ | ✅ |
| T07 GamePreset + DM プリセット | ✅ |
| T08 カードライブラリ画面 (S04) | ✅ |
| T09 カード登録/編集画面 (S05) | ✅ |
| T10 デッキ一覧画面 (S02) | ✅ |
| T11 デッキ編集画面 (S03) | ✅ |
| T12 ZoneView widget | ✅ |
| T13 CardWidget | ✅ |
| T14 SoloController | ✅ |
| T15 一人回し画面 (S06) | ✅ |
| T16 長押しメニュー | ✅ |
| T17 ゾーン一覧画面 (S09) | ✅ |
| T18 カード拡大表示 (S10) | ✅ |
| T19 設定画面基盤 (S11) | ✅ |
| T22-T28 対戦 (Firebase) | Phase 5 スタブ |

## 注意事項

- `*.g.dart` ファイルはコード生成で作られます (`build_runner` 実行後に生成)
- `firebase_options.dart` の `TODO` は `flutterfire configure` で上書き
- 対戦機能は Phase 5 実装予定
