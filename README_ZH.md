[English](./README.md) · 简体中文 · [繁體中文](./README_ZH-TW.md) · [日本語](./README_JA.md) · [日本語（ひらがな）](./README_JA-HIRA.md) · [Français](./README_FR.md) · [Русский](./README_RU.md)

# Argonote

一个用 Flutter 写的极简笔记应用：支持笔记的**创建、编辑、删除、列表展示**，正文支持 **Markdown**，可用**标签**和**文件夹**归类筛选，界面语言和主题配色可在**应用内设置**里切换，数据通过 `shared_preferences` 持久化在本地。

- 框架：Flutter 3.47 / Dart 3.13（Material 3）
- 平台：Android / iOS / Windows / macOS / Linux / Web
- 依赖：`shared_preferences`（存储）、`flutter_markdown_plus` + `markdown`（Markdown 渲染）、`flutter_localizations`（组件本地化）

## 功能

| 功能 | 说明 |
| --- | --- |
| 新建 | 首页右下角「写笔记」，进入编辑页写标题和正文 |
| 编辑 | 点击列表任意一条进入编辑页，改完点「保存」或直接返回（自动保存） |
| 删除 | 列表项**向左滑动**触发，二次确认后删除；编辑页右上角也有删除入口 |
| 撤销删除 | 删除后底部 SnackBar 提供「撤销」，连同原始 id 和创建时间一起还原 |
| Markdown | 正文支持标题、列表、代码块、链接、表格、引用；编辑页「编辑 / 预览」页签切换 |
| 标签 | 每条笔记可打多个标签，列表可按标签筛选 |
| 文件夹 | 笔记可归入文件夹，列表可按文件夹筛选；文件夹支持新建 / 重命名 / 删除 |
| 搜索 | 顶部搜索框，标题 / 正文 / 标签不区分大小写匹配，实时过滤 |
| 排序 | 按最近编辑时间倒序，刚改过的排在最前 |
| 自动保存 | 编辑页返回时（返回键 / 手势）自动落库，不会白写 |
| 界面语言 | 设置页可切换简体中文 / English / 日本語 / 繁體中文，立即生效并记住选择 |
| 主题配色 | 设置页可切换 6 种主色，以及跟随系统 / 浅色 / 深色 |
| 空笔记处理 | 标题、正文、标签、文件夹全为空则不保存；把已有笔记清空则视为删除 |

## 目录结构

```
lib/
├── main.dart                              # 入口：初始化 SharedPreferences，注入仓储与设置控制器
├── app.dart                               # MaterialApp：主题、语言、本地化、首页
├── models/
│   ├── note.dart                          # 笔记模型 + JSON 序列化（纯 Dart / 含标签与文件夹）
│   ├── folder.dart                        # 文件夹模型
│   ├── note_filter.dart                   # 筛选条件（关键词 + 文件夹 + 标签）与匹配逻辑
│   └── app_settings.dart                  # 应用设置（语言 / 主色 / 深浅模式）
├── data/
│   ├── note_repository.dart               # 笔记仓储抽象接口
│   ├── shared_prefs_note_repository.dart  # 笔记：shared_preferences 持久化实现
│   ├── in_memory_note_repository.dart     # 笔记：内存实现（测试用）
│   ├── folder_repository.dart             # 文件夹仓储抽象接口
│   ├── shared_prefs_folder_repository.dart
│   ├── in_memory_folder_repository.dart
│   ├── settings_repository.dart           # 设置仓储抽象接口
│   ├── shared_prefs_settings_repository.dart
│   └── in_memory_settings_repository.dart
├── settings/
│   └── settings_controller.dart           # ChangeNotifier：改设置 → 立即生效 → 落盘
├── l10n/
│   └── app_strings.dart                   # 四语言文案表（简中 / 英 / 日 / 繁中）
├── screens/
│   ├── note_list_screen.dart              # 列表页：搜索 / 筛选 / 侧滑删除 / 新建 / 设置入口
│   ├── note_edit_screen.dart              # 编辑页：Markdown 编辑与预览 / 标签 / 文件夹 / 保存
│   └── settings_screen.dart               # 设置页：语言、主色、外观（MD3）
├── widgets/
│   ├── note_tile.dart                     # 单条笔记展示（含标签、文件夹标记）
│   ├── filter_bar.dart                    # 文件夹 / 标签筛选栏
│   ├── folder_manager.dart                # 文件夹管理弹窗（新建 / 重命名 / 删除）
│   └── markdown_view.dart                 # Markdown 渲染视图（GFM）
└── utils/
    ├── date_format.dart                   # 极简时间格式化
    └── markdown_plain.dart                # Markdown → 纯文本（列表摘要用）
```

## 跑起来

```bash
flutter pub get
flutter run          # 选择设备后运行
flutter test         # 模型 / 仓储 / 筛选 / 多语言 / Markdown / 全流程 UI 用例
flutter analyze      # 静态检查
```

## 文档语言版本

仓库根目录下有四份内容一致的 README：

| 文档 | 说明 |
| --- | --- |
| `README.md` | English（默认入口） |
| `README_ZH.md` | 简体中文 |
| `README_ZH-TW.md` | 繁體中文 |
| `README_JA.md` | 日本語 |
| `README_JA-HIRA.md` | 日本語（ひらがな） |
| `README_FR.md` | Français |
| `README_RU.md` | Русский |

切换方式：在 GitHub 仓库首页点开顶部的语言链接即可；本地直接打开对应文件。
文档语言与**应用界面语言相互独立**——后者在应用内「设置 → 界面语言」里切换。

## 界面语言与主题（应用内设置）

列表页右上角齿轮图标进入设置页，三组 MD3 控件：

- **界面语言**：`RadioGroup` + `RadioListTile`，四种语言任选，选中即生效
- **主题配色**：6 个颜色圆点，点击切换主色（`ColorScheme.fromSeed` 派生整套配色）
- **外观**：`SegmentedButton` 切换跟随系统 / 浅色 / 深色

所有选择都会写入 `SharedPreferences`（key：`argonote.settings.v1`），下次启动自动恢复。

```dart
// settings/settings_controller.dart
Future<void> _apply(AppSettings next) async {
  _settings = next;
  notifyListeners();              // 先让界面立即变
  await _repository.save(next);   // 再落盘
}
```

```dart
// app.dart：用 ListenableBuilder 包住 MaterialApp，设置一变整棵树重建
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

## Markdown 支持

编辑页顶部是 `SegmentedButton`：「编辑」写 Markdown 源码，「预览」看渲染结果。
渲染用 `flutter_markdown_plus` + GitHub Flavored 扩展集，因此标题、列表、任务列表、围栏代码块、行内代码、链接、表格、引用、分割线都能正常显示：

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

列表页不渲染 Markdown（太重），而是用 `utils/markdown_plain.dart` 把标记剥掉当摘要：

```dart
Note.create(content: '# 标题\n\n- 第一项').plainPreview;   // => '标题 第一项'
```

## 标签与文件夹

```dart
class Note {
  final List<String> tags;   // 标签
  final String? folderId;    // 所属文件夹；null = 未归类
}
```

- 编辑页底部：文件夹用 `PopupMenuButton` 选（含「未归类」和「新建文件夹」），标签用 `Chip` + `ActionChip` 增删
- 列表页顶部 `FilterBar`：文件夹一行、标签一行，都是横滑的 `FilterChip`，可叠加关键词一起筛
- 筛选逻辑抽成 `models/note_filter.dart`，可以单独单测：

```dart
const filter = NoteFilter(folderId: 'folder-1', tag: '工作', keyword: '周报');
final visible = notes.where(filter.matches).toList();
```

- 删除文件夹只解除归属关系，笔记本身不会丢（列表里显示为「未归类」）

## 关键代码说明

### 1. 数据模型：只管结构，不管存储

`lib/models/note.dart` 是纯 Dart，不 import 任何 Flutter 包，单测里可以直接构造断言。

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;   // 列表按它倒序
  final List<String> tags;
  final String? folderId;

  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();
  String get plainPreview => plainTextFromMarkdown(content);
  bool get isBlank => title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty && folderId == null;

  factory Note.create({String title = '', String content = '', List<String> tags = const [], String? folderId});
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);   // 对缺失 / 脏数据做兜底
}
```

两个细节：

- `displayTitle` 把空标题统一成「无标题」，UI 里不用到处判空。
- `fromJson` 用 `DateTime.tryParse` + 空值兜底，**一条坏数据不会导致整个列表打不开**；旧版本没有 `tags` / `folderId` 字段的数据也能正常读出来。

### 2. 仓储抽象：UI 不碰存储细节

```dart
abstract class NoteRepository {
  Future<List<Note>> all();                    // 按更新时间倒序
  Future<Note?> findById(String id);
  Future<Note> create({required String title, required String content,
                       List<String> tags = const [], String? folderId});
  Future<Note> update({required String id, required String title, required String content,
                       required List<String> tags, String? folderId});
  Future<void> delete(String id);
  Future<void> restore(Note note);             // 撤销删除用
}
```

`FolderRepository`、`SettingsRepository` 同构。好处有两个：换存储（SQLite / Isar / 云端）时 UI 零改动；测试时塞内存实现就能跑，不需要 mock 平台通道。

### 3. 持久化：整体 JSON 读写

`shared_prefs_note_repository.dart` 把整个列表序列化成一个 JSON 数组存在单个 key 下：

```dart
static const String storageKey = 'argonote.notes.v1';

Future<void> _writeAll(List<Note> notes) async {
  _sortByUpdatedAtDesc(notes);
  await _prefs.setString(storageKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
```

key 带 `v1` 版本号，以后改数据结构可以做迁移。写入前统一排序，读取时就不用再排。

存储 key 一览：

| key | 内容 |
| --- | --- |
| `argonote.notes.v1` | 全部笔记 |
| `argonote.folders.v1` | 全部文件夹 |
| `argonote.settings.v1` | 语言 / 主色 / 深浅模式 |

> 为什么不用数据库：笔记这种「几百条以内、写入不频繁」的场景，整体读写更简单也更好调试。
> 数据量上来之后，照同一个接口换成 sqflite / isar 即可。

### 4. 依赖注入：一行切换实现

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();       // 先初始化引擎，才能 await 平台通道
  final prefs = await SharedPreferences.getInstance();

  final settingsController = SettingsController(SharedPrefsSettingsRepository(prefs));
  await settingsController.load();                 // 先恢复语言 / 配色，避免启动瞬间闪一下

  runApp(ArgonoteApp(
    repository: SharedPrefsNoteRepository(prefs),
    folderRepository: SharedPrefsFolderRepository(prefs),
    settingsController: settingsController,
  ));
}
```

### 5. 列表页：搜索、筛选、侧滑删除

`note_list_screen.dart` 用最朴素的 `StatefulWidget + setState`：

```dart
List<Note> get _visibleNotes => _notes.where(_filter.matches).toList(growable: false);
```

删除用 `Dismissible`：`confirmDismiss` 弹二次确认，`onDismissed` 才真正落库。
删完弹 SnackBar，点「撤销」调用 `restore(note)` 把原始数据整体写回——**不是新建一条同内容的新笔记**，id 和创建时间都保留。

```dart
Dismissible(
  key: ValueKey<String>(note.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) => _confirmDelete(note),
  onDismissed: (_) { _deleteNote(note); },
  child: NoteTile(note: note, onTap: () => _openEditor(note)),
)
```

### 6. 编辑页：返回即保存、更大的保存按钮

保存逻辑集中在一个方法里（含标签与文件夹）：

```dart
Future<void> _save() async {
  final isBlank = title.trim().isEmpty && content.trim().isEmpty && _tags.isEmpty && _folderId == null;
  if (isBlank) {
    if (existing != null) await widget.repository.delete(existing.id);   // 清空 = 删除
  } else if (existing == null) {
    await widget.repository.create(title: title, content: content, tags: _tags, folderId: _folderId);
  } else {
    await widget.repository.update(id: existing.id, title: title, content: content,
                                   tags: _tags, folderId: _folderId);
  }
}
```

返回自动保存靠 `PopScope` 拦截：

```dart
PopScope<Object?>(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _saveAndPop();          // 先保存再退出
  },
  child: Scaffold(...),
)
```

「保存」按钮比常规 `TextButton` 更大更醒目（最小 112×48、17px 粗体、带对勾图标），仍然保持 MD3 填充按钮样式，和 AppBar 其它控件对齐：

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

### 7. 多语言：一张表 + 一组 getter

`l10n/app_strings.dart` 用「key → 文案」的 Map 加类型安全的 getter，不引入代码生成：

```dart
class AppStrings {
  static AppStrings of(BuildContext context) => forLocale(Localizations.localeOf(context));
  String get newNote => text('newNote');
  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
}
```

四种语言共用同一套 key（单测会校验每个 key 在四种语言下都有值，防止漏翻）。未知语言回退到英文。

### 8. 测试

```
test/models/note_test.dart                      # 模型序列化、标签/文件夹、Markdown 摘要
test/models/note_filter_test.dart               # 关键词 / 标签 / 文件夹筛选组合
test/models/app_settings_test.dart              # 设置序列化、四语言文案齐全性
test/data/in_memory_note_repository_test.dart   # 笔记 CRUD + 撤销还原
test/data/in_memory_folder_repository_test.dart # 文件夹 CRUD
test/utils/markdown_test.dart                   # Markdown → 纯文本 + GFM 解析（含表格）
test/widgets/note_flow_test.dart                # 建-改-删全流程、搜索、标签/文件夹筛选、
                                                # Markdown 预览页签、设置页切换语言生效
```

## 已知事项

- Windows 桌面端运行时，Flutter 需要为插件创建目录符号链接
  （`windows/flutter/ephemeral/.plugin_symlinks`）。若提示 `ERROR_INVALID_FUNCTION`，
  开启系统「开发者模式」或以管理员身份运行即可；Android / iOS / Web 不受影响。
- Markdown 预览里的链接点击后会以 SnackBar 显示地址（没有引入 `url_launcher`，不主动跳转外链）。
