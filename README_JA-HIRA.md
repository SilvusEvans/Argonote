[English](./README.md) · [简体中文](./README_ZH.md) · [繁體中文](./README_ZH-TW.md) · [日本語](./README_JA.md) · 日本語（ひらがな） · [Français](./README_FR.md) · [Русский](./README_RU.md)
> **Doc status / 文档状态:** this translation still describes the v1 folder UI. The app now uses the notebook / section group / section / page hierarchy with multi-tab editing, trash, pinning and wiki links - see [README.md](./README.md) or [README_ZH.md](./README_ZH.md).

# Argonote

この アプリは、ふろく（Flutter）で つくった かんたんな メモアプリです。

- メモを つくったり、へんしゅうしたり、けしたり、いちらんで みたり できます
- ほんぶんは マークダウン（Markdown）に たいおうしています
- タグと フォルダーで しゅうりょう（せいり）できます
- アプリの なかで げんご（ことば）と テーマの いろを かえられます
- データは きず（端末）の なかに ほぞんされます

- つくったもの：Flutter 3.47 / Dart 3.13（マテリアル 3）
- つかえる もの：アンドロイド / iOS / ウィンドウズ / マック / リナックス / ウェブ
- つかっている ライブラリー：`shared_preferences`（ほぞん）、`flutter_markdown_plus` と `markdown`（マークダウン）、`flutter_localizations`（ぶひんの ほんやく）

## できること

| できること | せつめい |
| --- | --- |
| つくる | したの 「New note」を おして、タイトルと ほんぶんを かきます |
| へんしゅうする | いちらんの メモを タップします。「保存」を おすか、そのまま もどると ほぞんされます |
| けす | いちらんの メモを ひだりに すわいぷして、かくにんすると けせます。へんしゅうがめんにも けす ボタンが あります |
| けしたものを もどす | したに でる おしらせの 「元に戻す」で、もとの ばんごう（id）と つくった ひづけのまま もどります |
| マークダウン | みだし、リスト、コード、リンク、ひょう（テーブル）、いんよう など。「編集」と「プレビュー」を きりかえます |
| タグ | ひとつの メモに いくつでも タグを つけられます。タグで しぼりこめます |
| フォルダー | メモを フォルダーに いれて しぼりこめます。フォルダーは つくる／なまえを かえる／けす が できます |
| けんさく | うえの けんさくばこで、タイトル・ほんぶん・タグを すぐに さがせます |
| ならびじゅん | さいきん へんしゅうした ものが いちばん うえに きます |
| じどうほぞん | へんしゅうがめんから もどると、じどうで ほぞんされます |
| げんご | ふつうは エイゴ です。せっていで 简体中文 / English / 日本語 / 繁體中文 を きりかえます。すぐに かわり、えらんだ ものは おぼえられます |
| テーマの いろ | いろは 6しゅるい。ほかに システム／あかるい／くらい も えらべます |
| からっぽの メモ | タイトルも ほんぶんも タグも フォルダーも ない メモは ほぞんされません。ある メモを からっぽに すると けされます |

## プロジェクトの こうぞう

```
lib/
├── main.dart                              # いりぐち。ほぞんの じゅんびを して、リポジトリーを わたします
├── app.dart                               # MaterialApp。テーマ・げんご・ほんやく・いちらんがめん
├── models/
│   ├── note.dart                          # メモの モデルと JSON（タグと フォルダーつき）
│   ├── folder.dart                        # フォルダーの モデル
│   ├── note_filter.dart                   # しぼりこみ（ことば・フォルダー・タグ）の ルール
│   └── app_settings.dart                  # せってい（げんご・いろ・あかるさ）
├── data/
│   ├── note_repository.dart               # メモ ほぞんの インターフェース
│   ├── shared_prefs_note_repository.dart  # メモ：shared_preferences で ほぞん
│   ├── in_memory_note_repository.dart     # メモ：テストよう（おくに おくだけ）
│   ├── folder_repository.dart             # フォルダー ほぞんの インターフェース
│   ├── shared_prefs_folder_repository.dart
│   ├── in_memory_folder_repository.dart
│   ├── settings_repository.dart           # せってい ほぞんの インターフェース
│   ├── shared_prefs_settings_repository.dart
│   └── in_memory_settings_repository.dart
├── settings/
│   └── settings_controller.dart           # せっていを かえると すぐ はんえい して ほぞん
├── l10n/
│   └── app_strings.dart                   # よん げんごの ことば テーブル
├── screens/
│   ├── note_list_screen.dart              # いちらん：けんさく／しぼりこみ／すわいぷで けす／つくる／せってい
│   ├── note_edit_screen.dart              # へんしゅう：マークダウン・プレビュー・タグ・フォルダー・ほぞん
│   └── settings_screen.dart               # せってい：げんご・いろ・あかるさ（MD3）
├── widgets/
│   ├── note_tile.dart                     # いちらんの ひとつ（タグと フォルダーつき）
│   ├── filter_bar.dart                    # フォルダー／タグの しぼりこみ
│   ├── folder_manager.dart                # フォルダー そうさの ダイアログ
│   └── markdown_view.dart                 # マークダウンの ひょうじ
└── utils/
    ├── date_format.dart                   # ひづけの かたちを そろえる
    └── markdown_plain.dart                # マークダウン → へいぼんな ぶんしょう
```

## つかいかた

```bash
flutter pub get
flutter run          # きずを えらんで うごかす
flutter test         # モデル／ほぞん／しぼりこみ／げんご／マークダウン／UI の テスト
flutter analyze      # コードの チェック
```

## ドキュメントの げんご

この リポジトリーには、おなじ ないようの README が ななつ あります。

| ファイル | げんご |
| --- | --- |
| `README.md` | English（はじめに ひらかれる） |
| `README_ZH.md` | 简体中文 |
| `README_ZH-TW.md` | 繁體中文 |
| `README_JA.md` | 日本語 |
| `README_JA-HIRA.md` | 日本語（ひらがな） |
| `README_FR.md` | Français |
| `README_RU.md` | Русский |

きりかえかた：ページの いちばん うえの げんご リンクを クリックするか、ローカルで ファイルを ひらいてください。
ドキュメントの げんごと、アプリの がめんの げんごは べつです。アプリの ほうは 「設定 → 表示言語」で かえます。

## げんごと テーマ（アプリの せってい）

いちらんがめんの うえ みぎの はぐるまを おすと せっていがめんが ひらきます。マテリアル 3 の ぶひんが さん グループ：

- **げんご**：`RadioGroup` と `RadioListTile` で よん げんごから えらびます。えらんだ しゅんかんに かわります
- **テーマの いろ**：いろ まるが ろっこ。タップすると `ColorScheme.fromSeed` の もとになる いろが かわります
- **あかるさ**：`SegmentedButton` で システム／ライト／ダーク を きりかえます

えらんだ ものは すべて `SharedPreferences`（キー：`argonote.settings.v1`）に かきこまれ、つぎの 起動で もどります。

```dart
// settings/settings_controller.dart
Future<void> _apply(AppSettings next) async {
  _settings = next;
  notifyListeners();              // まず がめんを すぐ あたらしくする
  await _repository.save(next);   // それから ほぞんする
}
```

```dart
// app.dart：MaterialApp を ListenableBuilder で つつむので、せっていが かわると ぜんぶ つくりなおされる
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

## マークダウン

へんしゅうがめんの うえに 「編集」と「プレビュー」の きりかえが あります。
ひょうじには `flutter_markdown_plus` と GFM（ギットハブ の マークダウン）を つかうので、みだし・リスト・コード・リンク・ひょう・いんよう・けいせん が ただしく でます。

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

いちらんでは マークダウンを ひょうじ しません（おもいので）。かわりに `utils/markdown_plain.dart` で きごうを とります。

```dart
Note.create(content: '# タイトル\n\n- ひとつめ').plainPreview;   // => 'タイトル ひとつめ'
```

## タグと フォルダー

```dart
class Note {
  final List<String> tags;   // タグ
  final String? folderId;    // はいっている フォルダー。null は みぶんるい
}
```

- へんしゅうがめんの した：フォルダーは `PopupMenuButton` で えらびます（「未分類」と「フォルダーを作成」つき）。タグは `Chip` と `ActionChip` で ふやしたり へらしたり
- いちらんがめん：`FilterBar` に フォルダーの ぎょうと タグの ぎょう。けんさく ことばと いっしょに つかえます
- しぼりこみの ルールは `models/note_filter.dart` に わけてあるので、テストが かんたんです

```dart
const filter = NoteFilter(folderId: 'folder-1', tag: 'work', keyword: 'weekly');
final visible = notes.where(filter.matches).toList();
```

- フォルダーを けしても メモは けされません。「未分類」として でてきます

## コードの たいせつな ところ

### 1. モデル：かたち だけを もつ

`lib/models/note.dart` は Flutter を つかわない Dart だけの ファイルです。テストで そのまま つくって たしかめられます。

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;   // いちらんは これの あたらしい じゅん
  final List<String> tags;
  final String? folderId;

  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();
  String get plainPreview => plainTextFromMarkdown(content);
  bool get isBlank => title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty && folderId == null;

  factory Note.create({String title = '', String content = '', List<String> tags = const [], String? folderId});
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);   // データが なくても こわれない
}
```

たいせつな ところ ふたつ：

- `displayTitle` が からっぽの タイトルを まとめて かたづけるので、がめんの ほうで しらべなくて いいです。
- `fromJson` は `DateTime.tryParse` と よびを つかうので、**ひとつ こわれた データが あっても いちらん ぜんぶが ひらかなくなる ことは ありません**。

### 2. リポジトリー：がめんは ほぞんの ほうほうを しらない

```dart
abstract class NoteRepository {
  Future<List<Note>> all();                    // あたらしい じゅん
  Future<Note?> findById(String id);
  Future<Note> create({required String title, required String content,
                       List<String> tags = const [], String? folderId});
  Future<Note> update({required String id, required String title, required String content,
                       required List<String> tags, String? folderId});
  Future<void> delete(String id);
  Future<void> restore(Note note);             // 「元に戻す」よう
}
```

いいところ ふたつ：ほぞんの ほうほう（SQLite や くらうど）を かえても がめんは そのまま。テストでは おくに おく タイプを わたす だけで、プラットフォームの モックが いりません。

### 3. ほぞん：ぜんぶ ひとつの JSON

```dart
static const String storageKey = 'argonote.notes.v1';

Future<void> _writeAll(List<Note> notes) async {
  _sortByUpdatedAtDesc(notes);
  await _prefs.setString(storageKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
```

キーに `v1` という バージョンが あるので、あとで データの かたちを かえても うつしかえが できます。ならびかえは かく ときに するので、よむ ときは かるいです。

| キー | ないよう |
| --- | --- |
| `argonote.notes.v1` | すべての メモ |
| `argonote.folders.v1` | すべての フォルダー |
| `argonote.settings.v1` | げんご・いろ・あかるさ |

> データベースを つかわない りゆう：メモは すうひゃくけん ぐらいで、かきこみも おおくないので、ひとまとめの ほうが かんたんで しらべやすいです。おおくなったら sqflite や isar に とりかえれば いいです。

### 4. いちれい：いれかえは いちぎょう

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();       // プラットフォームを まつ まえに ひつよう
  final prefs = await SharedPreferences.getInstance();

  final settingsController = SettingsController(SharedPrefsSettingsRepository(prefs));
  await settingsController.load();                 // さいしょの がめんの まえに げんごと いろを もどす

  runApp(ArgonoteApp(
    repository: SharedPrefsNoteRepository(prefs),
    folderRepository: SharedPrefsFolderRepository(prefs),
    settingsController: settingsController,
  ));
}
```

### 5. いちらんがめん：けんさく・しぼりこみ・すわいぷ

```dart
List<Note> get _visibleNotes => _notes.where(_filter.matches).toList(growable: false);
```

けす ときは `Dismissible` を つかいます。`confirmDismiss` で かくにんして、`onDismissed` で ほんとうに けします。
そのあと 「元に戻す」を おすと `restore(note)` が、**コピーではなく もとの データ**を もどすので、ばんごうと つくった ひづけが のこります。

```dart
Dismissible(
  key: ValueKey<String>(note.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) => _confirmDelete(note),
  onDismissed: (_) { _deleteNote(note); },
  child: NoteTile(note: note, onTap: () => _openEditor(note)),
)
```

### 6. へんしゅうがめん：もどるとき ほぞん、おおきな ほぞん ボタン

```dart
Future<void> _save() async {
  final isBlank = title.trim().isEmpty && content.trim().isEmpty && _tags.isEmpty && _folderId == null;
  if (isBlank) {
    if (existing != null) await widget.repository.delete(existing.id);   // からっぽ = けす
  } else if (existing == null) {
    await widget.repository.create(title: title, content: content, tags: _tags, folderId: _folderId);
  } else {
    await widget.repository.update(id: existing.id, title: title, content: content,
                                   tags: _tags, folderId: _folderId);
  }
}
```

もどるときの じどうほぞんは `PopScope` で しています。

```dart
PopScope<Object?>(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _saveAndPop();          // ほぞんしてから でる
  },
  child: Scaffold(...),
)
```

「保存」ボタンは ふつうの ボタンより おおきく めだつように しています（112×48、じゅうなな ぴくせる、チェックの アイコン）。マテリアル 3 の ボタンの ままなので、ほかの ボタンと ならびも そろっています。

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

### 7. げんご：テーブル ひとつと ゲッター

```dart
class AppStrings {
  static AppStrings of(BuildContext context) => forLocale(Localizations.localeOf(context));
  String get newNote => text('newNote');
  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
}
```

よん げんごは おなじ キーを つかいます（テストで すべての げんごに すべての キーが あるか たしかめています）。しらない げんごは えいごに なります。

### 8. テスト

```
test/models/note_test.dart                      # モデル、タグ、フォルダー、マークダウンの ようやく
test/models/note_filter_test.dart               # ことば・タグ・フォルダーの しぼりこみ
test/models/app_settings_test.dart              # せっていと よん げんごの じゅんび
test/data/in_memory_note_repository_test.dart   # メモの つくる／よむ／かえる／けす
test/data/in_memory_folder_repository_test.dart # フォルダーの そうさ
test/utils/markdown_test.dart                   # マークダウン → ぶんしょう、ひょうの かいせき
test/widgets/note_flow_test.dart                # つくる→へんしゅう→けす、けんさく、しぼりこみ、
                                                # プレビュー、げんごの きりかえ
```

## ちゅういじこう

- ウィンドウズの デスクトップでは、Flutter が プラグインの ための シンボリックリンクを つくります
  （`windows/flutter/ephemeral/.plugin_symlinks`）。`ERROR_INVALID_FUNCTION` が でたら、
  「開発者モード」を オンに するか、管理者として うごかしてください。アンドロイド／iOS／ウェブは だいじょうぶです。
- プレビューで リンクを おすと、URL が したの おしらせに でます（`url_launcher` は つかっていないので、そと の リンクを ひとりでに ひらきません）。
