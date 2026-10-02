[English](./README.md) · [简体中文](./README_ZH.md) · 繁體中文 · [日本語](./README_JA.md) · [日本語（ひらがな）](./README_JA-HIRA.md) · [Français](./README_FR.md) · [Русский](./README_RU.md)
> **Doc status / 文档状态:** this translation still describes the v1 folder UI. The app now uses the notebook / section group / section / page hierarchy with multi-tab editing, trash, pinning and wiki links - see [README.md](./README.md) or [README_ZH.md](./README_ZH.md).

# Argonote

一個用 Flutter 寫的極簡筆記應用：支援筆記的**新增、編輯、刪除、列表展示**，正文支援 **Markdown**，可用**標籤**與**資料夾**分類篩選，介面語言與主題配色可在**應用內設定**切換，資料透過 `shared_preferences` 保存在本機。

- 框架：Flutter 3.47 / Dart 3.13（Material 3）
- 平台：Android / iOS / Windows / macOS / Linux / Web
- 依賴：`shared_preferences`（儲存）、`flutter_markdown_plus` + `markdown`（Markdown 渲染）、`flutter_localizations`（元件本地化）

## 功能

| 功能 | 說明 |
| --- | --- |
| 新增 | 點首頁右下角「新增筆記」，進入編輯頁寫標題與正文 |
| 編輯 | 點列表任一筆進入編輯頁，按「儲存」或直接返回（自動儲存） |
| 刪除 | 列表項目**向左滑動**觸發，二次確認後刪除；編輯頁右上角也有刪除入口 |
| 復原刪除 | 刪除後底部 SnackBar 提供「復原」，連同原始 id 與建立時間一起還原 |
| Markdown | 正文支援標題、清單、程式碼區塊、連結、表格、引言；編輯頁「編輯 / 預覽」分頁切換 |
| 標籤 | 每則筆記可打多個標籤，列表可依標籤篩選 |
| 資料夾 | 筆記可歸入資料夾並依資料夾篩選；資料夾可新增 / 重新命名 / 刪除 |
| 搜尋 | 頂部搜尋框，標題 / 正文 / 標籤不分大小寫比對，即時過濾 |
| 排序 | 依最近編輯時間倒序，剛改過的排最前 |
| 自動儲存 | 編輯頁返回時（返回鍵 / 手勢）自動寫入，不會白寫 |
| 介面語言 | 設定頁可切換 简体中文 / English / 日本語 / 繁體中文，立即生效並記住選擇 |
| 主題配色 | 設定頁提供 6 種主色，以及跟隨系統 / 淺色 / 深色 |
| 空白筆記 | 標題、正文、標籤、資料夾全空則不儲存；把既有筆記清空視為刪除 |

## 目錄結構

```
lib/
├── main.dart                              # 入口：初始化 SharedPreferences，注入倉儲與設定控制器
├── app.dart                               # MaterialApp：主題、語言、本地化、首頁
├── models/
│   ├── note.dart                          # 筆記模型 + JSON（純 Dart，含標籤與資料夾）
│   ├── folder.dart                        # 資料夾模型
│   ├── note_filter.dart                   # 篩選條件（關鍵字 + 資料夾 + 標籤）與比對邏輯
│   └── app_settings.dart                  # 應用設定（語言 / 主色 / 深淺模式）
├── data/
│   ├── note_repository.dart               # 筆記倉儲抽象介面
│   ├── shared_prefs_note_repository.dart  # 筆記：shared_preferences 持久化實作
│   ├── in_memory_note_repository.dart     # 筆記：記憶體實作（測試用）
│   ├── folder_repository.dart             # 資料夾倉儲抽象介面
│   ├── shared_prefs_folder_repository.dart
│   ├── in_memory_folder_repository.dart
│   ├── settings_repository.dart           # 設定倉儲抽象介面
│   ├── shared_prefs_settings_repository.dart
│   └── in_memory_settings_repository.dart
├── settings/
│   └── settings_controller.dart           # ChangeNotifier：改設定 → 立即生效 → 寫入
├── l10n/
│   └── app_strings.dart                   # 四語言文案表（簡中 / 英 / 日 / 繁中）
├── screens/
│   ├── note_list_screen.dart              # 列表頁：搜尋 / 篩選 / 側滑刪除 / 新增 / 設定入口
│   ├── note_edit_screen.dart              # 編輯頁：Markdown 編輯與預覽 / 標籤 / 資料夾 / 儲存
│   └── settings_screen.dart               # 設定頁：語言、主色、外觀（MD3）
├── widgets/
│   ├── note_tile.dart                     # 單筆筆記展示（含標籤與資料夾標記）
│   ├── filter_bar.dart                    # 資料夾 / 標籤篩選列
│   ├── folder_manager.dart                # 資料夾管理對話框（新增 / 重新命名 / 刪除）
│   └── markdown_view.dart                 # Markdown 渲染檢視（GFM）
└── utils/
    ├── date_format.dart                   # 極簡時間格式化
    └── markdown_plain.dart                # Markdown → 純文字（列表摘要用）
```

## 開始使用

```bash
flutter pub get
flutter run          # 選擇裝置後執行
flutter test         # 模型 / 倉儲 / 篩選 / 多語言 / Markdown / 全流程 UI 用例
flutter analyze      # 靜態檢查
```

## 文件語言版本

儲存庫根目錄下有一致內容的四份 README：

| 檔案 | 語言 |
| --- | --- |
| `README.md` | English（預設入口） |
| `README_ZH.md` | 简体中文 |
| `README_ZH-TW.md` | 繁體中文 |
| `README_JA.md` | 日本語 |
| `README_JA-HIRA.md` | 日本語（ひらがな） |
| `README_FR.md` | Français |
| `README_RU.md` | Русский |

切換方式：在 GitHub 儲存庫頁首點擊語言連結即可；本機直接開啟對應檔案。
文件語言與**應用介面語言彼此獨立**——後者在應用內「設定 → 介面語言」切換。

## 介面語言與主題（應用內設定）

點列表頁右上角齒輪圖示進入設定頁，三組 MD3 控制項：

- **介面語言**：`RadioGroup` + `RadioListTile`，四種語言任選，選中即生效
- **主題配色**：6 個色票圓點，點擊切換 `ColorScheme.fromSeed` 的來源色
- **外觀**：`SegmentedButton` 切換跟隨系統 / 淺色 / 深色

所有選擇都會寫入 `SharedPreferences`（key：`argonote.settings.v1`），下次啟動自動還原。

```dart
// settings/settings_controller.dart
Future<void> _apply(AppSettings next) async {
  _settings = next;
  notifyListeners();              // 先讓介面立即更新
  await _repository.save(next);   // 再寫入儲存
}
```

```dart
// app.dart：用 ListenableBuilder 包住 MaterialApp，設定一變整棵樹重建
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

## Markdown 支援

編輯頁頂部是 `SegmentedButton`：「編輯」寫 Markdown 原始碼，「預覽」看渲染結果。
渲染使用 `flutter_markdown_plus` + GitHub Flavored 擴充集，因此標題、清單、待辦清單、圍欄與行內程式碼、連結、表格、引言、分隔線都能正確顯示：

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

列表頁不渲染 Markdown（太重），改用 `utils/markdown_plain.dart` 去掉標記當摘要：

```dart
Note.create(content: '# 標題\n\n- 第一項').plainPreview;   // => '標題 第一項'
```

## 標籤與資料夾

```dart
class Note {
  final List<String> tags;   // 標籤
  final String? folderId;    // 所屬資料夾；null = 未分類
}
```

- 編輯頁底部：資料夾用 `PopupMenuButton` 選（含「未分類」與「新增資料夾」），標籤用 `Chip` + `ActionChip` 增刪
- 列表頁頂部 `FilterBar`：資料夾一列、標籤一列，都是橫向滑動的 `FilterChip`，可與關鍵字疊加
- 比對邏輯抽在 `models/note_filter.dart`，可單獨測試：

```dart
const filter = NoteFilter(folderId: 'folder-1', tag: 'work', keyword: 'weekly');
final visible = notes.where(filter.matches).toList();
```

- 刪除資料夾只解除歸屬，筆記本身不會遺失（列表顯示為「未分類」）

## 關鍵程式碼說明

### 1. 資料模型：只管結構，不管儲存

`lib/models/note.dart` 是純 Dart，不 import 任何 Flutter 套件，測試裡可直接建構與斷言。

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;   // 列表依它倒序
  final List<String> tags;
  final String? folderId;

  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();
  String get plainPreview => plainTextFromMarkdown(content);
  bool get isBlank => title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty && folderId == null;

  factory Note.create({String title = '', String content = '', List<String> tags = const [], String? folderId});
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);   // 對缺失 / 髒資料有容錯
}
```

兩個細節：

- `displayTitle` 把空標題統一成「无标题」，UI 不必到處判空。
- `fromJson` 使用 `DateTime.tryParse` 加空值兜底，**一筆壞資料不會讓整個列表打不開**；舊版沒有 `tags` / `folderId` 欄位的資料也能正常讀取。

### 2. 倉儲抽象：UI 不碰儲存細節

```dart
abstract class NoteRepository {
  Future<List<Note>> all();                    // 依更新時間倒序
  Future<Note?> findById(String id);
  Future<Note> create({required String title, required String content,
                       List<String> tags = const [], String? folderId});
  Future<Note> update({required String id, required String title, required String content,
                       required List<String> tags, String? folderId});
  Future<void> delete(String id);
  Future<void> restore(Note note);             // 復原刪除用
}
```

`FolderRepository`、`SettingsRepository` 同構。好處有兩個：換儲存（SQLite / Isar / 雲端）時 UI 零改動；測試時塞入記憶體實作即可，不必 mock 平台通道。

### 3. 持久化：整體 JSON 讀寫

`shared_prefs_note_repository.dart` 把整個列表序列化成一個 JSON 陣列存在單一 key 下：

```dart
static const String storageKey = 'argonote.notes.v1';

Future<void> _writeAll(List<Note> notes) async {
  _sortByUpdatedAtDesc(notes);
  await _prefs.setString(storageKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
```

key 帶 `v1` 版本號，日後改資料結構可做遷移。寫入前統一排序，讀取就不必再排。

儲存 key 一覽：

| key | 內容 |
| --- | --- |
| `argonote.notes.v1` | 全部筆記 |
| `argonote.folders.v1` | 全部資料夾 |
| `argonote.settings.v1` | 語言 / 主色 / 深淺模式 |

> 為什麼不用資料庫：筆記這種「幾百條以內、寫入不頻繁」的場景，整體讀寫更單純也更好除錯。
> 資料量上來之後，照同一個介面換成 sqflite / isar 即可。

### 4. 依賴注入：一行切換實作

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();       // 先初始化引擎，才能 await 平台通道
  final prefs = await SharedPreferences.getInstance();

  final settingsController = SettingsController(SharedPrefsSettingsRepository(prefs));
  await settingsController.load();                 // 先還原語言 / 配色，避免啟動瞬間閃一下

  runApp(ArgonoteApp(
    repository: SharedPrefsNoteRepository(prefs),
    folderRepository: SharedPrefsFolderRepository(prefs),
    settingsController: settingsController,
  ));
}
```

### 5. 列表頁：搜尋、篩選、側滑刪除

`note_list_screen.dart` 維持最單純的 `StatefulWidget + setState`：

```dart
List<Note> get _visibleNotes => _notes.where(_filter.matches).toList(growable: false);
```

刪除用 `Dismissible`：`confirmDismiss` 彈二次確認，`onDismissed` 才真正從儲存移除。
刪除後 SnackBar 提供「復原」，呼叫 `restore(note)` 把**原始資料**整體寫回——不是新建一份副本，id 與建立時間都保留。

```dart
Dismissible(
  key: ValueKey<String>(note.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) => _confirmDelete(note),
  onDismissed: (_) { _deleteNote(note); },
  child: NoteTile(note: note, onTap: () => _openEditor(note)),
)
```

### 6. 編輯頁：返回即儲存、更大的儲存按鈕

儲存邏輯集中在同一個方法（含標籤與資料夾）：

```dart
Future<void> _save() async {
  final isBlank = title.trim().isEmpty && content.trim().isEmpty && _tags.isEmpty && _folderId == null;
  if (isBlank) {
    if (existing != null) await widget.repository.delete(existing.id);   // 清空 = 刪除
  } else if (existing == null) {
    await widget.repository.create(title: title, content: content, tags: _tags, folderId: _folderId);
  } else {
    await widget.repository.update(id: existing.id, title: title, content: content,
                                   tags: _tags, folderId: _folderId);
  }
}
```

返回自動儲存由 `PopScope` 攔截：

```dart
PopScope<Object?>(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _saveAndPop();          // 先儲存再離開
  },
  child: Scaffold(...),
)
```

「儲存」按鈕比一般 `TextButton` 更大更醒目（最小 112×48、17px 粗體、含勾選圖示），同時維持 MD3 填充按鈕樣式，與 AppBar 其他元件對齊：

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

### 7. 多語言：一張表 + 一組 getter

`l10n/app_strings.dart` 用「key → 文案」的 Map 搭配型別安全的 getter，不引入程式碼產生：

```dart
class AppStrings {
  static AppStrings of(BuildContext context) => forLocale(Localizations.localeOf(context));
  String get newNote => text('newNote');
  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
}
```

四種語言共用同一套 key（單測會驗證每個 key 在四種語言下都有值，避免漏翻）。未知語言回退到英文。

### 8. 測試

```
test/models/note_test.dart                      # 模型序列化、標籤/資料夾、Markdown 摘要
test/models/note_filter_test.dart               # 關鍵字 / 標籤 / 資料夾篩選組合
test/models/app_settings_test.dart              # 設定序列化、四語言文案完整性
test/data/in_memory_note_repository_test.dart   # 筆記 CRUD + 復原還原
test/data/in_memory_folder_repository_test.dart # 資料夾 CRUD
test/utils/markdown_test.dart                   # Markdown → 純文字 + GFM 解析（含表格）
test/widgets/note_flow_test.dart                # 增-改-刪全流程、搜尋、標籤/資料夾篩選、
                                                # Markdown 預覽分頁、設定頁切換語言生效
```

## 已知事項

- Windows 桌面端執行時，Flutter 需要為外掛建立目錄符號連結
  （`windows/flutter/ephemeral/.plugin_symlinks`）。若出現 `ERROR_INVALID_FUNCTION`，
  開啟系統「開發者模式」或以管理員身分執行即可；Android / iOS / Web 不受影響。
- Markdown 預覽裡點擊連結會用 SnackBar 顯示網址（未引入 `url_launcher`，不主動開啟外部連結）。
