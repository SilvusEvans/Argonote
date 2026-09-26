# Argonote

一个用 Flutter 写的极简笔记应用：支持笔记的**创建、编辑、删除、列表展示**，数据通过 `shared_preferences` 持久化在本地，杀掉 App 后重新打开内容还在。

- 框架：Flutter 3.47 / Dart 3.13（Material 3，浅色 / 深色跟随系统）
- 平台：Android / iOS / Windows / macOS / Linux / Web（存储层统一走 `shared_preferences`）
- 依赖：除 Flutter SDK 外只有 `shared_preferences` 一个运行时依赖

## 功能

| 功能 | 说明 |
| --- | --- |
| 新建 | 首页右下角「写笔记」，进入编辑页写标题和正文 |
| 编辑 | 点击列表任意一条进入编辑页，改完点「保存」或直接返回（自动保存） |
| 删除 | 列表项**向左滑动**触发，二次确认后删除；编辑页右上角也有删除入口 |
| 撤销删除 | 删除后底部 SnackBar 提供「撤销」，连同原始 id 和创建时间一起还原 |
| 搜索 | 顶部搜索框，标题 / 正文不区分大小写匹配，实时过滤 |
| 排序 | 按最近编辑时间倒序，刚改过的排在最前 |
| 自动保存 | 编辑页返回时（返回键 / 手势）自动落库，不会白写 |
| 空笔记处理 | 标题和正文都为空则不保存；把已有笔记清空则视为删除 |

## 目录结构

```
lib/
├── main.dart                              # 入口：初始化 SharedPreferences，注入仓储
├── app.dart                               # MaterialApp：主题、深色模式、首页
├── models/
│   └── note.dart                          # 数据模型 + JSON 序列化（纯 Dart，无 Flutter 依赖）
├── data/
│   ├── note_repository.dart               # 仓储抽象接口（UI 只依赖它）
│   ├── shared_prefs_note_repository.dart  # shared_preferences 持久化实现
│   └── in_memory_note_repository.dart     # 内存实现，供测试 / 预览使用
├── screens/
│   ├── note_list_screen.dart              # 列表页：展示 / 搜索 / 侧滑删除 / 新建入口
│   └── note_edit_screen.dart              # 编辑页：新建 & 编辑 & 删除 & 自动保存
├── widgets/
│   └── note_tile.dart                     # 单条笔记的展示组件
└── utils/
    └── date_format.dart                   # 极简时间格式化（当天显示时分，今年显示月日）

test/
├── models/note_test.dart                       # 模型序列化、copyWith 单测
├── data/in_memory_note_repository_test.dart    # 仓储 CRUD 单测
└── widgets/note_flow_test.dart                 # 建 → 改 → 删 全流程组件测试
```

## 跑起来

```bash
flutter pub get
flutter run          # 选择设备后运行
flutter test         # 模型 + 仓储 + 全流程 UI 用例
flutter analyze      # 静态检查
```

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

  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();
  bool   get isBlank => title.trim().isEmpty && content.trim().isEmpty;

  factory Note.create({String title = '', String content = ''});  // id 用微秒时间戳
  Note copyWith({String? title, String? content, DateTime? updatedAt});
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);   // 对缺失 / 脏数据做兜底
}
```

两个细节：

- `displayTitle` 把空标题统一成「无标题」，UI 里不用到处判空。
- `fromJson` 用 `DateTime.tryParse` + 空值兜底，**一条坏数据不会导致整个列表打不开**。

### 2. 仓储抽象：UI 不碰存储细节

`lib/data/note_repository.dart` 定义接口，页面只依赖它：

```dart
abstract class NoteRepository {
  Future<List<Note>> all();                                  // 按更新时间倒序
  Future<Note?> findById(String id);
  Future<Note> create({required String title, required String content});
  Future<Note> update({required String id, required String title, required String content});
  Future<void> delete(String id);
  Future<void> restore(Note note);                           // 撤销删除用
}
```

好处有两个：换存储（SQLite / Isar / 云端）时 UI 零改动；测试时塞 `InMemoryNoteRepository` 就能跑，不需要 mock 平台通道。

### 3. 持久化：整体 JSON 读写

`shared_prefs_note_repository.dart` 把整个列表序列化成一个 JSON 数组存在单个 key 下：

```dart
static const String storageKey = 'argonote.notes.v1';

Future<List<Note>> _readAll() async {
  final raw = _prefs.getString(storageKey);
  if (raw == null || raw.isEmpty) return <Note>[];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return <Note>[];
  final notes = <Note>[];
  for (final item in decoded) {
    if (item is Map<String, dynamic>) notes.add(Note.fromJson(item));
  }
  _sortByUpdatedAtDesc(notes);
  return notes;
}

Future<void> _writeAll(List<Note> notes) async {
  _sortByUpdatedAtDesc(notes);
  await _prefs.setString(storageKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
```

key 带 `v1` 版本号，以后改数据结构可以做迁移。写入前统一排序，读取时就不用再排。

> 为什么不用数据库：笔记这种「几百条以内、写入不频繁」的场景，整体读写更简单也更好调试。
> 数据量上来之后，照同一个接口换成 sqflite / isar 即可。

### 4. 依赖注入：一行切换实现

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();       // 先初始化引擎，才能 await 平台通道
  final prefs = await SharedPreferences.getInstance();
  runApp(ArgonoteApp(repository: SharedPrefsNoteRepository(prefs)));
}
```

仓储在 `main` 里创建并注入 `ArgonoteApp`，页面里没有一处 `new SharedPrefsNoteRepository`。

### 5. 列表页：搜索、空态、侧滑删除

`note_list_screen.dart` 用最朴素的 `StatefulWidget + setState`：

```dart
List<Note> get _visibleNotes {
  final keyword = _keyword.trim().toLowerCase();
  if (keyword.isEmpty) return _notes;
  return _notes.where((note) =>
      note.title.toLowerCase().contains(keyword) ||
      note.content.toLowerCase().contains(keyword)).toList();
}
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

### 6. 编辑页：返回即保存

`note_edit_screen.dart` 同时承担新建和编辑（`note == null` 即新建）。保存逻辑集中在一个方法里：

```dart
Future<void> _save() async {
  final title = _titleController.text;
  final content = _contentController.text;
  final existing = widget.note;

  if (title.trim().isEmpty && content.trim().isEmpty) {
    if (existing != null) await widget.repository.delete(existing.id);  // 清空 = 删除
  } else if (existing == null) {
    await widget.repository.create(title: title, content: content);
  } else {
    await widget.repository.update(id: existing.id, title: title, content: content);
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

### 7. 测试

- `test/models/note_test.dart`：JSON 往返、脏数据兜底、`copyWith` 行为
- `test/data/in_memory_note_repository_test.dart`：CRUD + 排序 + 撤销还原
- `test/widgets/note_flow_test.dart`：建 → 改 → 删 全流程组件测试，注入内存仓储，不碰真实存储

## 已知事项

- Windows 桌面端运行时，Flutter 需要为插件创建目录符号链接
  （`windows/flutter/ephemeral/.plugin_symlinks`）。若提示 `ERROR_INVALID_FUNCTION`，
  开启系统「开发者模式」或以管理员身份运行即可；Android / iOS / Web 不受影响。
