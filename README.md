English · [简体中文](./README_ZH.md) · [繁體中文](./README_ZH-TW.md) · [日本語](./README_JA.md) · [日本語（ひらがな）](./README_JA-HIRA.md) · [Français](./README_FR.md) · [Русский](./README_RU.md)

# Argonote

A minimal note-taking app built with Flutter: **create, edit, delete and list** notes, **Markdown** support in the body, **tags** and **folders** for organisation, an in-app **settings** screen for language and colour theme, and **local persistence** via `shared_preferences`.

- Framework: Flutter 3.47 / Dart 3.13 (Material 3)
- Platforms: Android / iOS / Windows / macOS / Linux / Web
- Dependencies: `shared_preferences` (storage), `flutter_markdown_plus` + `markdown` (Markdown rendering), `flutter_localizations` (widget localisation)

## Features

| Feature | Description |
| --- | --- |
| Create | Tap “New note” at the bottom right and write a title and body |
| Edit | Tap any note in the list; save with the button or just go back (auto-save) |
| Delete | **Swipe a list item to the left**, confirm, and it is gone; the edit screen has a delete action too |
| Undo delete | A SnackBar offers “Undo”, restoring the original id and creation time |
| Markdown | Headings, lists, code blocks, links, tables and quotes; switch between “Edit” and “Preview” tabs |
| Tags | Any number of tags per note; filter the list by tag |
| Folders | File notes into folders and filter by folder; folders can be created, renamed and deleted |
| Search | Search box at the top, case-insensitive over title / body / tags, live filtering |
| Ordering | Sorted by last edit time, most recent first |
| Auto-save | Leaving the edit screen (back button / gesture) persists everything |
| Language | Switch between 简体中文 / English / 日本語 / 繁體中文 in Settings; applies instantly and is remembered |
| Theme colour | 6 primary colours plus system / light / dark appearance |
| Empty notes | A note with no title, body, tag or folder is not saved; clearing an existing note deletes it |

## Project structure

```
lib/
├── main.dart                              # Entry point: init SharedPreferences, inject repositories
├── app.dart                               # MaterialApp: theme, locale, localisation, home
├── models/
│   ├── note.dart                          # Note model + JSON (pure Dart, with tags and folder)
│   ├── folder.dart                        # Folder model
│   ├── note_filter.dart                   # Filter (keyword + folder + tag) and matching logic
│   └── app_settings.dart                  # App settings (language / seed colour / theme mode)
├── data/
│   ├── note_repository.dart               # Note repository interface
│   ├── shared_prefs_note_repository.dart  # Notes: shared_preferences implementation
│   ├── in_memory_note_repository.dart     # Notes: in-memory implementation (tests)
│   ├── folder_repository.dart             # Folder repository interface
│   ├── shared_prefs_folder_repository.dart
│   ├── in_memory_folder_repository.dart
│   ├── settings_repository.dart           # Settings repository interface
│   ├── shared_prefs_settings_repository.dart
│   └── in_memory_settings_repository.dart
├── settings/
│   └── settings_controller.dart           # ChangeNotifier: change → apply instantly → persist
├── l10n/
│   └── app_strings.dart                   # String table for the four languages
├── screens/
│   ├── note_list_screen.dart              # List: search / filter / swipe to delete / new / settings
│   ├── note_edit_screen.dart              # Edit: Markdown editing & preview / tags / folder / save
│   └── settings_screen.dart               # Settings: language, colour, appearance (MD3)
├── widgets/
│   ├── note_tile.dart                     # One note in the list (with tag and folder badges)
│   ├── filter_bar.dart                    # Folder / tag filter chips
│   ├── folder_manager.dart                # Folder manager dialog (create / rename / delete)
│   └── markdown_view.dart                 # Markdown view (GitHub Flavored)
└── utils/
    ├── date_format.dart                   # Minimal date formatting
    └── markdown_plain.dart                # Markdown → plain text (list summary)
```

## Getting started

```bash
flutter pub get
flutter run          # pick a device and run
flutter test         # model / repository / filter / i18n / Markdown / full UI flow
flutter analyze      # static analysis
```

## Documentation languages

The repository ships four identical READMEs:

| File | Language |
| --- | --- |
| `README.md` | English (default entry) |
| `README_ZH.md` | 简体中文 |
| `README_ZH-TW.md` | 繁體中文 |
| `README_JA.md` | 日本語 |
| `README_JA-HIRA.md` | 日本語（ひらがな） |
| `README_FR.md` | Français |
| `README_RU.md` | Русский |

Switch by clicking the language links at the top of the repo page, or by opening the file locally.
The documentation language is **independent of the app UI language**, which is switched in **Settings → Language** inside the app.

## Language and theme (in-app settings)

Tap the gear icon in the list screen to open Settings — three groups of Material 3 controls:

- **Language**: `RadioGroup` + `RadioListTile` for the four languages, applied on selection
- **Theme colour**: 6 colour dots; tapping one swaps the seed colour used by `ColorScheme.fromSeed`
- **Appearance**: `SegmentedButton` for system / light / dark

Everything is written to `SharedPreferences` (key `argonote.settings.v1`) and restored on next launch.

```dart
// settings/settings_controller.dart
Future<void> _apply(AppSettings next) async {
  _settings = next;
  notifyListeners();              // UI updates immediately
  await _repository.save(next);   // then persist
}
```

```dart
// app.dart: MaterialApp wrapped in ListenableBuilder so the whole tree rebuilds on change
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

## Markdown support

A `SegmentedButton` at the top of the edit screen switches between “Edit” (Markdown source) and “Preview”.
Rendering uses `flutter_markdown_plus` with the GitHub Flavored extension set, so headings, lists, task lists, fenced and inline code, links, tables, quotes and horizontal rules all render correctly:

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

The list does not render Markdown (too heavy) — `utils/markdown_plain.dart` strips the markup for the summary line:

```dart
Note.create(content: '# Title\n\n- first item').plainPreview;   // => 'Title first item'
```

## Tags and folders

```dart
class Note {
  final List<String> tags;   // tags
  final String? folderId;    // owning folder; null = unfiled
}
```

- Edit screen bottom bar: a `PopupMenuButton` picks the folder (including “Unfiled” and “New folder”), tags are added/removed with `Chip` + `ActionChip`
- List screen: `FilterBar` shows one horizontally scrolling row of `FilterChip`s for folders and one for tags; both combine with the keyword
- The matching logic lives in `models/note_filter.dart` so it can be unit-tested on its own:

```dart
const filter = NoteFilter(folderId: 'folder-1', tag: 'work', keyword: 'weekly');
final visible = notes.where(filter.matches).toList();
```

- Deleting a folder only detaches notes — notes are never deleted and show up as “Unfiled”

## Key code walkthrough

### 1. Model: structure only, no storage

`lib/models/note.dart` is pure Dart with no Flutter imports, so tests can construct and assert freely.

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;   // list is sorted by this, descending
  final List<String> tags;
  final String? folderId;

  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();
  String get plainPreview => plainTextFromMarkdown(content);
  bool get isBlank => title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty && folderId == null;

  factory Note.create({String title = '', String content = '', List<String> tags = const [], String? folderId});
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);   // tolerant of missing / dirty data
}
```

Two details worth noting:

- `displayTitle` normalises empty titles, so the UI never has to null-check.
- `fromJson` uses `DateTime.tryParse` with fallbacks: **one corrupt record cannot break the whole list**, and data written before `tags` / `folderId` existed still loads fine.

### 2. Repository abstraction: the UI never touches storage

```dart
abstract class NoteRepository {
  Future<List<Note>> all();                    // by update time, descending
  Future<Note?> findById(String id);
  Future<Note> create({required String title, required String content,
                       List<String> tags = const [], String? folderId});
  Future<Note> update({required String id, required String title, required String content,
                       required List<String> tags, String? folderId});
  Future<void> delete(String id);
  Future<void> restore(Note note);             // used by undo
}
```

`FolderRepository` and `SettingsRepository` follow the same shape. Two benefits: swapping storage (SQLite / Isar / cloud) needs no UI change, and tests simply inject the in-memory implementations without mocking platform channels.

### 3. Persistence: one JSON document

`shared_prefs_note_repository.dart` serialises the whole list into a single key:

```dart
static const String storageKey = 'argonote.notes.v1';

Future<void> _writeAll(List<Note> notes) async {
  _sortByUpdatedAtDesc(notes);
  await _prefs.setString(storageKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
```

The key carries a `v1` version so future migrations are possible. Sorting happens on write, so reads stay cheap.

Storage keys:

| Key | Contents |
| --- | --- |
| `argonote.notes.v1` | All notes |
| `argonote.folders.v1` | All folders |
| `argonote.settings.v1` | Language / seed colour / theme mode |

> Why not a database: for a notebook with a few hundred low-frequency writes, a single document is simpler and easier to debug. When the data grows, swap in sqflite / isar behind the same interface.

### 4. Dependency injection: switch implementations in one line

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();       // needed before awaiting platform channels
  final prefs = await SharedPreferences.getInstance();

  final settingsController = SettingsController(SharedPrefsSettingsRepository(prefs));
  await settingsController.load();                 // restore language / colour before first frame

  runApp(ArgonoteApp(
    repository: SharedPrefsNoteRepository(prefs),
    folderRepository: SharedPrefsFolderRepository(prefs),
    settingsController: settingsController,
  ));
}
```

### 5. List screen: search, filters, swipe to delete

`note_list_screen.dart` sticks to plain `StatefulWidget + setState`:

```dart
List<Note> get _visibleNotes => _notes.where(_filter.matches).toList(growable: false);
```

Deletion uses `Dismissible`: `confirmDismiss` asks for confirmation, `onDismissed` actually removes the note from storage.
A SnackBar then offers “Undo”, which calls `restore(note)` and writes the **original record** back — not a fresh copy — so id and creation time survive.

```dart
Dismissible(
  key: ValueKey<String>(note.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) => _confirmDelete(note),
  onDismissed: (_) { _deleteNote(note); },
  child: NoteTile(note: note, onTap: () => _openEditor(note)),
)
```

### 6. Edit screen: save on back, bigger save button

All saving goes through one method (tags and folder included):

```dart
Future<void> _save() async {
  final isBlank = title.trim().isEmpty && content.trim().isEmpty && _tags.isEmpty && _folderId == null;
  if (isBlank) {
    if (existing != null) await widget.repository.delete(existing.id);   // cleared = deleted
  } else if (existing == null) {
    await widget.repository.create(title: title, content: content, tags: _tags, folderId: _folderId);
  } else {
    await widget.repository.update(id: existing.id, title: title, content: content,
                                   tags: _tags, folderId: _folderId);
  }
}
```

Auto-save on back is handled by `PopScope`:

```dart
PopScope<Object?>(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _saveAndPop();          // save first, then leave
  },
  child: Scaffold(...),
)
```

The save button is deliberately larger and more prominent than a plain `TextButton` (min 112×48, 17px bold, check icon) while staying a regular MD3 filled button aligned with the rest of the AppBar:

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

### 7. Localisation: one table, typed getters

`l10n/app_strings.dart` uses a “key → text” map with typed getters, no code generation:

```dart
class AppStrings {
  static AppStrings of(BuildContext context) => forLocale(Localizations.localeOf(context));
  String get newNote => text('newNote');
  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
}
```

All four languages share one key set (a unit test asserts every key exists in every language, so nothing can be left untranslated). Unknown locales fall back to English.

### 8. Tests

```
test/models/note_test.dart                      # model serialisation, tags/folder, Markdown summary
test/models/note_filter_test.dart               # keyword / tag / folder filter combinations
test/models/app_settings_test.dart              # settings serialisation, completeness of all locales
test/data/in_memory_note_repository_test.dart   # note CRUD + undo restore
test/data/in_memory_folder_repository_test.dart # folder CRUD
test/utils/markdown_test.dart                   # Markdown → plain text + GFM parsing (incl. tables)
test/widgets/note_flow_test.dart                # full create-edit-delete flow, search, tag/folder filters,
                                                # Markdown preview tab, language switch from Settings
```

## Known issues

- On Windows desktop Flutter creates directory symlinks for plugins
  (`windows/flutter/ephemeral/.plugin_symlinks`); `ERROR_INVALID_FUNCTION` means you need
  Developer Mode or an elevated shell. Android / iOS / Web are unaffected.
- Tapping a link in the Markdown preview shows the URL in a SnackBar (`url_launcher` is not included, so the app never opens external links on its own).
