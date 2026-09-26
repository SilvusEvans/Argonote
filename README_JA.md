[English](./README.md) · [简体中文](./README_ZH.md) · [繁體中文](./README_ZH-TW.md) · 日本語 · [日本語（ひらがな）](./README_JA-HIRA.md) · [Français](./README_FR.md) · [Русский](./README_RU.md)

# Argonote

Flutter で作ったミニマルなメモアプリです。メモの**作成・編集・削除・一覧表示**に加え、本文で **Markdown** が使え、**タグ**と**フォルダ**で整理でき、アプリ内**設定**から表示言語とテーマカラーを切り替えられます。データは `shared_preferences` でローカルに永続化されます。

- フレームワーク：Flutter 3.47 / Dart 3.13（Material 3）
- プラットフォーム：Android / iOS / Windows / macOS / Linux / Web
- 依存パッケージ：`shared_preferences`（保存）、`flutter_markdown_plus` + `markdown`（Markdown 描画）、`flutter_localizations`（ウィジェットのローカライズ）

## 機能

| 機能 | 説明 |
| --- | --- |
| 作成 | 右下の「新規メモ」からタイトルと本文を書く |
| 編集 | 一覧のメモをタップ。「保存」を押すか、そのまま戻ると自動保存される |
| 削除 | 一覧を**左にスワイプ**して確認後に削除。編集画面にも削除ボタンあり |
| 削除の取り消し | SnackBar の「元に戻す」で、元の id・作成日時ごと復元 |
| Markdown | 見出し、リスト、コードブロック、リンク、表、引用に対応。「編集 / プレビュー」を切り替え |
| タグ | 1 つのメモに複数タグ。タグで絞り込み可能 |
| フォルダ | フォルダに分類して絞り込み。フォルダは作成 / 改名 / 削除が可能 |
| 検索 | 上部の検索欄でタイトル・本文・タグを大文字小文字を無視してリアルタイム絞り込み |
| 並び順 | 更新時刻の降順（最近編集したものが先頭） |
| 自動保存 | 編集画面から戻る（戻るボタン / ジェスチャ）と自動的に保存 |
| 表示言語 | 設定から 简体中文 / English / 日本語 / 繁體中文 を切り替え。即時反映され、選択は保存される |
| テーマカラー | 6 色のメインカラーと、システム / ライト / ダークの外観 |
| 空のメモ | タイトル・本文・タグ・フォルダがすべて空なら保存しない。既存メモを空にすると削除扱い |

## ディレクトリ構成

```
lib/
├── main.dart                              # エントリポイント：SharedPreferences を初期化し依存を注入
├── app.dart                               # MaterialApp：テーマ / 言語 / ローカライズ / ホーム
├── models/
│   ├── note.dart                          # メモモデル + JSON（純粋な Dart、タグとフォルダを含む）
│   ├── folder.dart                        # フォルダモデル
│   ├── note_filter.dart                   # 絞り込み条件（キーワード + フォルダ + タグ）と判定ロジック
│   └── app_settings.dart                  # アプリ設定（言語 / メインカラー / 外観）
├── data/
│   ├── note_repository.dart               # メモリポジトリの抽象
│   ├── shared_prefs_note_repository.dart  # メモ：shared_preferences 実装
│   ├── in_memory_note_repository.dart     # メモ：メモリ実装（テスト用）
│   ├── folder_repository.dart             # フォルダリポジトリの抽象
│   ├── shared_prefs_folder_repository.dart
│   ├── in_memory_folder_repository.dart
│   ├── settings_repository.dart           # 設定リポジトリの抽象
│   ├── shared_prefs_settings_repository.dart
│   └── in_memory_settings_repository.dart
├── settings/
│   └── settings_controller.dart           # ChangeNotifier：変更 → 即時反映 → 保存
├── l10n/
│   └── app_strings.dart                   # 4 言語の文言テーブル
├── screens/
│   ├── note_list_screen.dart              # 一覧：検索 / 絞り込み / スワイプ削除 / 新規 / 設定
│   ├── note_edit_screen.dart              # 編集：Markdown 編集とプレビュー / タグ / フォルダ / 保存
│   └── settings_screen.dart               # 設定：言語・カラー・外観（MD3）
├── widgets/
│   ├── note_tile.dart                     # 一覧の 1 件（タグとフォルダのバッジ付き）
│   ├── filter_bar.dart                    # フォルダ / タグの絞り込みチップ
│   ├── folder_manager.dart                # フォルダ管理ダイアログ（作成 / 改名 / 削除）
│   └── markdown_view.dart                 # Markdown 表示（GitHub Flavored）
└── utils/
    ├── date_format.dart                   # シンプルな日時フォーマット
    └── markdown_plain.dart                # Markdown → プレーンテキスト（一覧の要約用）
```

## 実行方法

```bash
flutter pub get
flutter run          # デバイスを選んで実行
flutter test         # モデル / リポジトリ / 絞り込み / 多言語 / Markdown / UI フロー
flutter analyze      # 静的解析
```

## ドキュメントの言語

リポジトリには内容が同一の README が 4 つあります。

| ファイル | 言語 |
| --- | --- |
| `README.md` | English（既定の入口） |
| `README_ZH.md` | 简体中文 |
| `README_ZH-TW.md` | 繁體中文 |
| `README_JA.md` | 日本語 |
| `README_JA-HIRA.md` | 日本語（ひらがな） |
| `README_FR.md` | Français |
| `README_RU.md` | Русский |

切り替え方：リポジトリページ上部の言語リンクをクリック、またはローカルで該当ファイルを開くだけです。
ドキュメントの言語と**アプリの UI 言語は独立**しています。後者はアプリ内の「設定 → 表示言語」で切り替えます。

## 言語とテーマ（アプリ内設定）

一覧画面右上の歯車アイコンから設定画面を開きます。Material 3 のコントロールが 3 グループ：

- **表示言語**：`RadioGroup` + `RadioListTile` で 4 言語から選択、選んだ瞬間に反映
- **テーマカラー**：6 つのカラーサークル。タップすると `ColorScheme.fromSeed` のシードカラーが変わる
- **外観**：`SegmentedButton` で システム / ライト / ダーク を切り替え

選択内容は `SharedPreferences`（キー `argonote.settings.v1`）に保存され、次回起動時に復元されます。

```dart
// settings/settings_controller.dart
Future<void> _apply(AppSettings next) async {
  _settings = next;
  notifyListeners();              // まず UI を即座に更新
  await _repository.save(next);   // それから永続化
}
```

```dart
// app.dart：MaterialApp を ListenableBuilder で包み、設定変更でツリー全体を再構築
return ListenableBuilder(
  listenable: settingsController,
  builder: (context, _) {
    final settings = settingsController.settings;
    return MaterialApp(
      theme: _buildTheme(settings.seedColor, Brightness.light),
      darkTheme: _buildTheme(settings.seedColor, Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLanguage.values.map((l) => l.locale).toList(),
      localizationsDelegates: const [...],
      home: NoteListScreen(...),
    );
  },
);
```

## Markdown 対応

編集画面上部の `SegmentedButton` で「編集」（Markdown ソース）と「プレビュー」を切り替えます。
描画は `flutter_markdown_plus` + GitHub Flavored 拡張セットなので、見出し・リスト・タスクリスト・囲みコードとインラインコード・リンク・表・引用・水平線が正しく表示されます。

```dart
// widgets/markdown_view.dart
MarkdownBody(
  data: data,
  selectable: true,
  extensionSet: md.ExtensionSet.gitHubFlavored,
  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
    codeblockDecoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    tableBorder: TableBorder.all(color: theme.colorScheme.outlineVariant),
    ...
  ),
);
```

一覧では Markdown を描画せず（重いため）、`utils/markdown_plain.dart` でマークアップを外して要約にします。

```dart
Note.create(content: '# タイトル\n\n- 項目1').plainPreview;   // => 'タイトル 項目1'
```

## タグとフォルダ

```dart
class Note {
  final List<String> tags;   // タグ
  final String? folderId;    // 所属フォルダ。null = 未分類
}
```

- 編集画面下部：フォルダは `PopupMenuButton` で選択（「未分類」「フォルダを作成」を含む）。タグは `Chip` + `ActionChip` で追加・削除
- 一覧画面：`FilterBar` にフォルダ行とタグ行があり、どちらも横スクロールの `FilterChip`。キーワードと組み合わせ可能
- 判定ロジックは `models/note_filter.dart` に分離しているので単体テストできます：

```dart
const filter = NoteFilter(folderId: 'folder-1', tag: 'work', keyword: 'weekly');
final visible = notes.where(filter.matches).toList();
```

- フォルダを削除してもメモは削除されず、「未分類」として表示されます

## 主要コードの解説

### 1. モデル：構造だけを扱い、保存は扱わない

`lib/models/note.dart` は Flutter を import しない純粋な Dart なので、テストで直接組み立てて検証できます。

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;   // 一覧はこれの降順
  final List<String> tags;
  final String? folderId;

  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();
  String get plainPreview => plainTextFromMarkdown(content);
  bool get isBlank => title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty && folderId == null;

  factory Note.create({String title = '', String content = '', List<String> tags = const [], String? folderId});
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);   // 欠損 / 不正データに寛容
}
```

ポイントは 2 つ：

- `displayTitle` が空タイトルを正規化するので、UI 側で毎回判定しなくて済みます。
- `fromJson` は `DateTime.tryParse` とフォールバックを使うため、**1 件の壊れたデータで一覧全体が開けなくなることがありません**。`tags` / `folderId` が無い旧データもそのまま読めます。

### 2. リポジトリ抽象：UI は保存手段を知らない

```dart
abstract class NoteRepository {
  Future<List<Note>> all();                    // 更新時刻の降順
  Future<Note?> findById(String id);
  Future<Note> create({required String title, required String content,
                       List<String> tags = const [], String? folderId});
  Future<Note> update({required String id, required String title, required String content,
                       required List<String> tags, String? folderId});
  Future<void> delete(String id);
  Future<void> restore(Note note);             // 取り消し用
}
```

`FolderRepository` と `SettingsRepository` も同じ形です。利点は 2 つ：保存手段（SQLite / Isar / クラウド）を変えても UI は無変更、テストではメモリ実装を差し込むだけでプラットフォームチャネルのモックが不要。

### 3. 永続化：JSON をまとめて読み書き

`shared_prefs_note_repository.dart` はリスト全体を 1 つのキーにシリアライズします。

```dart
static const String storageKey = 'argonote.notes.v1';

Future<void> _writeAll(List<Note> notes) async {
  _sortByUpdatedAtDesc(notes);
  await _prefs.setString(storageKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
```

キーに `v1` のバージョンを付けてあるので、将来のマイグレーションが可能です。並べ替えは書き込み時に行うため、読み取りは軽いままです。

保存キー一覧：

| キー | 内容 |
| --- | --- |
| `argonote.notes.v1` | すべてのメモ |
| `argonote.folders.v1` | すべてのフォルダ |
| `argonote.settings.v1` | 言語 / メインカラー / 外観 |

> データベースを使わない理由：数百件程度で書き込みも多くないメモ帳なら、まとめて読み書きする方がシンプルでデバッグもしやすいためです。
> 数据量が増えたら、同じインターフェースのまま sqflite / isar に差し替えれば OK です。

### 4. 依存注入：実装の差し替えは 1 行

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();       // プラットフォームチャネルを await する前に必要
  final prefs = await SharedPreferences.getInstance();

  final settingsController = SettingsController(SharedPrefsSettingsRepository(prefs));
  await settingsController.load();                 // 起動直後のテーマのちらつきを防ぐ

  runApp(ArgonoteApp(
    repository: SharedPrefsNoteRepository(prefs),
    folderRepository: SharedPrefsFolderRepository(prefs),
    settingsController: settingsController,
  ));
}
```

### 5. 一覧画面：検索・絞り込み・スワイプ削除

`note_list_screen.dart` は素朴な `StatefulWidget + setState` です。

```dart
List<Note> get _visibleNotes => _notes.where(_filter.matches).toList(growable: false);
```

削除は `Dismissible`：`confirmDismiss` で確認ダイアログを出し、`onDismissed` で実際に保存領域から消します。
その後 SnackBar の「元に戻す」は `restore(note)` を呼び、**コピーではなく元のレコード**を書き戻すため、id と作成日時が保たれます。

```dart
Dismissible(
  key: ValueKey<String>(note.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) => _confirmDelete(note),
  onDismissed: (_) { _deleteNote(note); },
  child: NoteTile(note: note, onTap: () => _openEditor(note)),
)
```

### 6. 編集画面：戻ると保存、大きな保存ボタン

保存処理は 1 か所に集約しています（タグとフォルダも含む）：

```dart
Future<void> _save() async {
  final isBlank = title.trim().isEmpty && content.trim().isEmpty && _tags.isEmpty && _folderId == null;
  if (isBlank) {
    if (existing != null) await widget.repository.delete(existing.id);   // 空にした = 削除
  } else if (existing == null) {
    await widget.repository.create(title: title, content: content, tags: _tags, folderId: _folderId);
  } else {
    await widget.repository.update(id: existing.id, title: title, content: content,
                                   tags: _tags, folderId: _folderId);
  }
}
```

戻るときの自動保存は `PopScope` で横取りします：

```dart
PopScope<Object?>(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _saveAndPop();          // 保存してから離脱
  },
  child: Scaffold(...),
)
```

「保存」ボタンは通常の `TextButton` より大きく目立たせています（最小 112×48、17px 太字、チェックアイコン）。MD3 の FilledButton のままなので AppBar の他の要素とも揃っています。

```dart
FilledButton.icon(
  onPressed: _saveAndPop,
  icon: const Icon(Icons.check_rounded, size: 22),
  label: Text(strings.save),
  style: FilledButton.styleFrom(
    minimumSize: const Size(112, 48),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  ),
)
```

### 7. 多言語：1 つのテーブル + 型安全な getter

`l10n/app_strings.dart` は「キー → 文言」の Map に型付き getter を組み合わせた方式で、コード生成は使いません。

```dart
class AppStrings {
  static AppStrings of(BuildContext context) => forLocale(Localizations.localeOf(context));
  String get newNote => text('newNote');
  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
}
```

4 言語は同じキーセットを共有します（単体テストで全キーが全言語に存在することを検証しているため、翻訳漏れを防げます）。未知のロケールは英語にフォールバックします。

### 8. テスト

```
test/models/note_test.dart                      # モデルのシリアライズ、タグ/フォルダ、Markdown 要約
test/models/note_filter_test.dart               # キーワード / タグ / フォルダの絞り込み組み合わせ
test/models/app_settings_test.dart              # 設定のシリアライズ、4 言語の網羅性
test/data/in_memory_note_repository_test.dart   # メモの CRUD + 取り消し復元
test/data/in_memory_folder_repository_test.dart # フォルダの CRUD
test/utils/markdown_test.dart                   # Markdown → プレーンテキスト + GFM 解析（表を含む）
test/widgets/note_flow_test.dart                # 作成-編集-削除の通しフロー、検索、タグ/フォルダ絞り込み、
                                                # Markdown プレビュー、設定からの言語切り替え反映
```

## 既知の事項

- Windows デスクトップでは、Flutter がプラグイン用のディレクトリシンボリックリンク
  （`windows/flutter/ephemeral/.plugin_symlinks`）を作成します。`ERROR_INVALID_FUNCTION` が出る場合は
  開発者モードを有効にするか、管理者権限で実行してください。Android / iOS / Web は影響を受けません。
- Markdown プレビューでリンクをタップすると URL を SnackBar で表示します（`url_launcher` は入れていないため、外部リンクを勝手に開きません）。
