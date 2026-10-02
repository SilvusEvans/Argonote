[English](./README.md) · 简体中文 · [繁體中文](./README_ZH-TW.md) · [日本語](./README_JA.md) · [日本語（ひらがな）](./README_JA-HIRA.md) · [Français](./README_FR.md) · [Русский](./README_RU.md)

# Argonote

一个用 Flutter 写的本地笔记应用：OneNote 式的**笔记本 → 分区组 → 分区 → 页面**层级、桌面**多标签页**编辑、正文支持 **Markdown**（含 `[[双链]]` 跳转），可用**标签**归类筛选，界面语言和主题配色可在**应用内设置**里切换，数据通过 `shared_preferences` 持久化在本地。

- 框架：Flutter 3.47 / Dart 3.13（Material 3）
- 平台：Android / iOS / Windows / macOS / Linux / Web
- 依赖：`shared_preferences`（存储）、`flutter_markdown_plus` + `markdown`（Markdown 渲染）、`characters`（字素安全截断/计数）、`flutter_localizations`（组件本地化）

## 功能

| 功能 | 说明 |
| --- | --- |
| 笔记本体系 | OneNote 风格层级：笔记本 > 分区组（可选）> 分区 > 页面；左侧树支持新建 / 重命名 / 删除，删父级不丢笔记（降级为「未分组」）。旧版文件夹数据启动时自动迁移成分区 |
| 多标签页 | 桌面宽屏三栏（树 / 页面列表 / 编辑器），编辑器可同时打开多篇笔记为标签；未保存显示圆点、右键可关闭其它/全部标签；窄屏自动回退整屏编辑 |
| 新建 / 编辑 | 列表右上角「+」新建标签页；输入停顿 800ms 自动保存，关标签、切走也不丢 |
| 三视图 | 编辑 / 分栏（左写右渲）/ 预览三种模式一键切换 |
| 编辑工具栏 | 加粗、斜体、标题、列表、任务列表、代码、引用、链接、表格、分割线一键插入，已包裹的内容再点即剥离 |
| Markdown 双链 | 正文写 `[[另一页标题]]`，预览点击直接打开对应笔记标签页 |
| 统计 | 实时显示字符（按字素簇，emoji/中文不拆坏）、字数、行数 |
| 复制为 Markdown | 一键把「标题 + 正文」复制到剪贴板，方便导出 |
| 置顶 | 任意笔记可置顶，永远排在列表最前；左树有「置顶」视图 |
| 回收站 | 删除先进回收站（软删除），可还原或彻底删除，支持一键清空；列表删除的 SnackBar 仍可撤销 |
| 搜索 | 左树定位范围（全部 / 笔记本 / 分区 / 未分组）+ 关键词实时过滤标题 / 正文 / 标签 |
| 排序 | 最近修改 / 最近创建 / 标题升序，三种可切换 |
| 字符显示修复 | 摘要截断与工具栏编辑都按字素簇切分，选区端点落在半截 emoji 上时自动外扩到完整字素，不再产生孤立代理对（渲染成替换符） |
| 标签 | 每条笔记可打多个标签，列表有标签快筛条 |
| 界面语言 | 简体中文 / English / 日本語 / 繁體中文，立即生效并记住选择 |
| 主题配色 | 6 种主色 + 跟随系统 / 浅色 / 深色 |
| 空笔记处理 | 全空的新笔记不落库；把已有笔记清空则自动进回收站 |

## 目录结构

```
lib/
├── main.dart                              # 入口：初始化 SharedPreferences，注入仓储与设置控制器
├── app.dart                               # MaterialApp：主题、语言、本地化、首页 HomeShell
├── models/
│   ├── note.dart                          # 页面（笔记）模型 + JSON 序列化（分区/置顶/回收站/字素统计）
│   ├── notebook.dart                      # 笔记本 / 分区组 / 分区 模型
│   ├── note_tab.dart                      # 编辑器标签页运行时状态（持有输入控制器）
│   ├── note_filter.dart                   # 筛选（关键词/标签/排序）+ 左树范围 NoteScope 与匹配逻辑
│   └── app_settings.dart                  # 应用设置（语言 / 主色 / 深浅模式）
├── data/
│   ├── note_repository.dart               # 笔记仓储抽象接口
│   ├── shared_prefs_note_repository.dart  # 笔记：shared_preferences 持久化实现
│   ├── in_memory_note_repository.dart     # 笔记：内存实现（测试用）
│   ├── notebook_repository.dart           # 笔记本体系仓储抽象接口
│   ├── shared_prefs_notebook_repository.dart  # 含旧版文件夹 → 分区的一次性迁移
│   ├── in_memory_notebook_repository.dart
│   ├── settings_repository.dart           # 设置仓储抽象接口
│   ├── shared_prefs_settings_repository.dart
│   └── in_memory_settings_repository.dart
├── settings/
│   └── settings_controller.dart           # ChangeNotifier：改设置 → 立即生效 → 落盘
├── l10n/
│   └── app_strings.dart                   # 四语言文案表（简中 / 英 / 日 / 繁中）
├── screens/
│   ├── home_shell.dart                    # 三栏外壳：树 / 列表 / 标签编辑器 + 自动保存 + 回收站
│   └── settings_screen.dart               # 设置页：语言、主色、外观（MD3）
├── widgets/
│   ├── notebook_tree.dart                 # OneNote 风格左树（右键/更多菜单增删改）
│   ├── note_tile.dart                     # 单条笔记展示（置顶、分区、动作菜单）
│   ├── tab_strip.dart                     # 多标签条（脏标记、中键区域右键菜单、溢出滚动）
│   ├── note_editor.dart                   # 编辑器面板（工具栏/三视图/分区归属/标签/统计）
│   ├── folder_manager.dart                # 文件夹管理弹窗（新建 / 重命名 / 删除）
│   └── markdown_view.dart                 # Markdown 渲染视图（GFM）
└── utils/
    ├── date_format.dart                   # 极简时间格式化
    ├── markdown_tools.dart                # 工具栏插入/包裹、[[双链]]预处理（纯函数）
    └── markdown_plain.dart                # Markdown → 纯文本（列表摘要用，字素安全截断）
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

## 标签与笔记本体系

```dart
class Note {
  final List<String> tags;    // 标签
  final String? sectionId;    // 所属分区；null = 未分组
  final bool pinned;          // 置顶
  final bool trashed;         // 在回收站里（软删除）
}
```

- 编辑器底部元信息行：分区用 `PopupMenuButton` 选（列出「未分组」和全部 `笔记本 / 分区`），标签用 `Chip` 增删
- 左侧 `NotebookTree` 决定「看哪个范围」，顶部搜索框决定「匹配什么」，两者互不耦合
- 范围 + 筛选 + 排序全部抽进 `models/note_filter.dart`，纯 Dart，可单独跑断言：

```dart
const scope = NoteScope.notebook('nb-1');
final visible = const NoteFilter(tag: '工作', keyword: '周报')
    .apply(notes, scope, notebookSectionIds: {'s-1', 's-2'});
```

- 删除分区 / 分区组 / 笔记本只解除归属，笔记本身不丢（落回「未分组」）；删除走回收站，可还原

## 键盘快捷键

桌面端在 `HomeShell` 上用 `CallbackShortcuts` 注册（Windows 上这些组合键都不会和文本框的默认编辑快捷键冲突）：

| 快捷键 | 作用 |
| --- | --- |
| `Ctrl+N` | 新建一个空白标签页 |
| `Ctrl+W` | 关闭当前标签页（关之前会把未保存内容落库） |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | 在标签页之间前后循环 |
| `Ctrl+S` | 立即保存当前标签页（不等 800ms 自动保存） |

`CallbackShortcuts` 只有在焦点落在它的子树内时才会命中，而"点列表条目 / 点分区"这类操作
并不必然让某个节点拿到焦点（`primaryFocus` 会停在最外层的 `FocusScope`，此时按组合键没有
反应）。所以 shell 在快捷键作用域内部放了一个 `Focus(autofocus: true, skipTraversal: true)`
锚点，保证刚打开软件、还没点进任何输入框时这些组合键就可用；`skipTraversal` 让它不参与
Tab 遍历，不会打断正常的焦点跳转。

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
test/models/note_filter_test.dart               # 范围（笔记本/分区/未分组/置顶/回收站）+ 排序 + 关键词/标签
test/models/app_settings_test.dart              # 设置序列化、四语言文案齐全性
test/data/in_memory_note_repository_test.dart   # 笔记 CRUD、置顶、软删除、解除分区
test/data/in_memory_notebook_repository_test.dart   # 笔记本 / 分区组 / 分区 层级动作
test/data/shared_prefs_notebook_repository_test.dart # 旧文件夹 → 分区的一次性迁移与往返读写
test/l10n/app_strings_test.dart                 # 四种语言 key 完整性与回退
test/utils/markdown_test.dart                   # Markdown → 纯文本 + GFM 解析（含表格）
test/utils/markdown_tools_test.dart             # 工具栏包裹/前缀/插块 + 双链预处理
test/widgets/note_flow_test.dart                # 三栏全流程、多标签开关、自动保存、回收站还原、
                                                # 双链预览、窄屏返回、快捷键、切换语言生效
```

## 跑测试与自检

```bash
flutter test                      # Widget + 单元测试
dart run tool/selfcheck.dart      # 纯逻辑层断言（80 项），退出码即结果
```

`tool/selfcheck.dart` 不依赖 Flutter 运行时：模型、筛选、文本工具、内存仓储都是纯 Dart，
所以遇到 `flutter test` 跑不起来的环境（例如回环 TCP 被本机防火墙/安全软件拦掉，测试套件
会在 "Connection closed before test suite loaded" 处失败）时，仍然可以用 Dart VM 直接验证逻辑层。

### 运行时自检 `tool/runtime_harness.dart`

逻辑层之外还需要「界面真的渲染出来了」的证据。`flutter test` 要连回环 VM Service、
`flutter build windows` 要为插件建符号链接，两者都可能被本机环境挡掉；`flutter_tester`
这两样都不需要，于是 harness 把真实的 `ArgonoteApp`（内存仓储 + 一批含中文标点、Emoji、
ZWJ 序列、代码块、表格、双链的种子数据）装进 `flutter_tester`，用合成指针事件点界面，
每步断言界面上确实出现/没出现相应文字，再把 `RepaintBoundary` 光栅化成 PNG 落盘。

```bash
# 1) 只编译 Dart（-t 指向 harness，不动 lib/main.dart）
flutter build bundle -t tool/runtime_harness.dart

# 2) 离屏运行；$SDK 是 Flutter SDK 根目录
$SDK/bin/cache/artifacts/engine/windows-x64/flutter_tester.exe \
  --non-interactive --enable-software-rendering \
  --flutter-assets-dir=build/flutter_assets \
  --packages=.dart_tool/package_config.json \
  --icu-data-file-path=$SDK/bin/cache/artifacts/engine/windows-x64/icudtl.dat \
  build/flutter_assets/kernel_blob.bin
```

- `ARGONOTE_SHOT_DIR`：截图输出目录，默认 `D:/tmp/runtime`，换成自己的可写目录即可。
- 退出码 0 = 全部断言通过；未通过项逐行打印 `FAIL …`，末尾 `DONE failures=N`。
- 最后一张 `10_zoom.png` 用 6 倍像素比放大预览页，专门用来看字形有没有缺（emoji、码点回退）。
- `ARGONOTE_WIDE=1` 再跑一轮走桌面三栏分支：`flutter_tester` 的窗口固定 800×600 逻辑像素，
  低于 `HomeShell` 的 `_wideBreakpoint(920)`，所以 harness 用 `MediaQuery` 覆盖 + 直接改
  `RenderView.configuration` 把根视图撑到 1440×900。指针事件与 KeyEvent 仍走框架真实管线
  （键盘从 `PlatformDispatcher.onKeyData` 注入 `ui.KeyData`，`synthesized: true` 才会立刻
  flush 成 KeyMessage），因此这一轮能同时验证 `Ctrl+N` / `Ctrl+Tab` / `Ctrl+W`。
- 注意别用 `TestWidgetsFlutterBinding`：`LiveTestWidgetsFlutterBinding` 会接管指针事件分发，
  合成点击全部失效。
- 跑完记得 `flutter build bundle`（默认入口 `lib/main.dart`）覆盖回去，否则
  `build/flutter_assets` 里留的是 harness 的 kernel。

## 已知事项

- Windows 桌面端构建时，Flutter 需要为插件创建目录符号链接
  （`windows/flutter/ephemeral/.plugin_symlinks`）。这要求两件事同时满足：
  项目所在分区是 NTFS（exFAT / FAT32 不支持符号链接，会报 `ERROR_INVALID_FUNCTION`），
  并且系统已开启「开发者模式」或以管理员身份运行。Android / iOS / Web 不受影响。
- 代码块与行内代码指定了 `Consolas` + 中文 / emoji 回退字体，而不是 Android 的逻辑字体名
  `monospace`（Windows 解析不到该名，会让代码块里的中文和 emoji 显示成方块）。
- Windows 的 Segoe UI Emoji 不带「区域指示符」旗标字形，所以国旗类 emoji（两个区域
  指示符拼成的序列）在 Windows 桌面端会显示成 `CN` 这样的两个字母（macOS / Android
  正常）。这是系统字体缺失，不是渲染链路的问题；要显示旗标只能自带一套旗标字体。
  家庭 / 职业这类 ZWJ 组合序列（`👨‍👩‍👧‍👑`、`👨💻`）能正常合成，
  运行时截图里已逐字确认。
- Markdown 预览里的 `http(s)` 链接点击后只显示地址、不会跳浏览器（没有引入 `url_launcher`）；
  `[[双链]]` 则按标题匹配打开对应笔记的标签页。
