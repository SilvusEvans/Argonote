[简体中文](./README_ZH.md) · English · [繁體中文](./README_ZH-TW.md) · [日本語](./README_JA.md) · [日本語（ひらがな）](./README_JA-HIRA.md) · [Français](./README_FR.md) · [Русский](./README_RU.md)

# Argonote

A local-first note app written in Flutter, with an OneNote-style hierarchy
(**notebook → section group → section → page**), **multi-tab editing** on the desktop,
**Markdown** body text including `[[wiki links]]`, **tags** for cross-cutting filtering,
and in-app **language / theme** settings. Everything is stored on-device through
`shared_preferences` — no account, no server.

- Framework: Flutter 3.47 / Dart 3.13 (Material 3)
- Platforms: Android / iOS / Windows / macOS / Linux / Web
- Dependencies: `shared_preferences` (storage), `flutter_markdown_plus` + `markdown`
  (rendering), `characters` (grapheme-safe truncation and counting), `flutter_localizations`

## Features

| Feature | Notes |
| --- | --- |
| Notebook hierarchy | Notebook > section group (optional) > section > page. The left tree creates, renames and deletes nodes; deleting a parent never loses notes, they fall back to "Unfiled". Legacy folder data is migrated to sections once at startup, ids preserved |
| Multi-tab editor | Wide screens show three panes (tree / list / editor). The editor holds several notes as tabs; an unsaved tab shows a dot, right-click closes others or all. Narrow screens fall back to full-screen editing with a back button |
| Autosave | 800 ms after you stop typing, and a final flush when a tab closes |
| Three view modes | Edit / split (type left, rendered right) / preview |
| Markdown toolbar | Bold, italic, heading, list, task list, code, quote, link, table, rule — toggling wrapped text unwraps it |
| Wiki links | Write `[[page title]]`; clicking it in the preview opens that note in a new tab |
| Live stats | Character count by grapheme cluster (emoji and CJK are never split), word count, line count |
| Copy as Markdown | Copies "title + body" to the clipboard for quick export |
| Pinning | Pinned notes always sort first; there is a dedicated tree view |
| Trash | Deleting is soft: restore, delete forever, or empty the trash. The list's snack bar still offers undo |
| Search + scopes | The tree picks the scope (all / notebook / group / section / pinned / unfiled / trash), the search box filters title, body and tags case-insensitively |
| Sorting | Recently modified / recently created / title A→Z |
| Character display fix | Previews truncate by grapheme cluster, and toolbar edits snap selection ends to cluster boundaries, so neither can split a UTF-16 surrogate pair and leave `￼` in the text |
| Tags | Multiple tags per note, one-tap filtering |
| Language | Simplified Chinese / English / Japanese / Traditional Chinese, applied instantly and remembered |
| Theme | Six accent colours, plus system / light / dark |
| Blank-note handling | A still-blank new draft is never persisted; clearing an existing note sends it to the trash |

## Keyboard shortcuts

Registered with `CallbackShortcuts` in `HomeShell`. None of these collide with
Flutter's default text-editing bindings on Windows, so they work while the caret is in a field.

| Shortcut | Action |
| --- | --- |
| `Ctrl+N` | New blank tab |
| `Ctrl+W` | Close the current tab (saves first if needed) |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Cycle tabs forward / backward |
| `Ctrl+S` | Save the current tab immediately |

`CallbackShortcuts` only fires while focus sits inside its subtree, and clicking a list
row or a section does not necessarily move focus anywhere (`primaryFocus` stays on the
outermost `FocusScope`). The shell therefore wraps itself in a
`Focus(autofocus: true, skipTraversal: true)` anchor, so the bindings work straight
after launch; `skipTraversal` keeps the anchor out of Tab traversal.

## Project structure

```
lib/
├── main.dart                              # Bootstrap: SharedPreferences, inject repositories
├── app.dart                               # MaterialApp: theme, locale, HomeShell
├── models/
│   ├── note.dart                          # Page model + JSON (section, pin, trash, stats)
│   ├── notebook.dart                      # Notebook / SectionGroup / Section
│   ├── note_tab.dart                      # Runtime tab state, owns the editing controllers
│   ├── note_filter.dart                   # Scope, keyword, tag, sort + matching
│   └── app_settings.dart                  # Language / accent / theme mode
├── data/
│   ├── note_repository.dart               # Abstract store
│   ├── shared_prefs_note_repository.dart  # Persisted implementation
│   ├── in_memory_note_repository.dart     # Test implementation
│   ├── notebook_repository.dart           # Notebook hierarchy interface
│   ├── shared_prefs_notebook_repository.dart  # Includes the one-off folders → sections migration
│   ├── in_memory_notebook_repository.dart
│   ├── settings_repository.dart           # (+ shared_prefs / in_memory implementations)
├── settings/settings_controller.dart      # ChangeNotifier: apply instantly, then persist
├── l10n/app_strings.dart                    # Four language tables behind typed getters
├── screens/
│   ├── home_shell.dart                    # Three panes, tabs, autosave, trash, shortcuts
│   └── settings_screen.dart               # Language / colour / theme mode
├── utils/
│   ├── markdown_plain.dart                # Markdown → plain preview text
│   ├── markdown_tools.dart                # Toolbar edits + `[[wiki link]]` preprocessing
│   └── date_format.dart                   # Locale-aware timestamps
└── widgets/
    ├── notebook_tree.dart                 # Scope list + notebook tree with context menu
    ├── note_tile.dart                     # One row in the note list
    ├── tab_strip.dart                     # Tab bar (dirty dot, close, context menu)
    ├── note_editor.dart                   # Toolbar, fields, view modes, meta row
    └── markdown_view.dart                 # GFM rendering with theme-derived styles
```

## Getting started

```bash
flutter pub get
flutter run -d windows          # or: chrome, android, macos, linux
flutter build windows --release
```

Android / iOS / Web need nothing special. A Windows build needs symlink support:
the project must live on an NTFS volume (exFAT and FAT32 cannot hold the plugin
links under `windows/flutter/ephemeral/.plugin_symlinks`, which surfaces as
`ERROR_INVALID_FUNCTION`), and Developer Mode must be enabled in Windows settings
(or run the build from an elevated shell).

## Storage

One JSON document per entity, all under a single preference key each:

```
argonote.notes.v1          # every note, including trashed ones
argonote.notebookTree.v1   # notebooks, section groups, sections
argonote.settings.v1       # language, accent colour, theme mode
argonote.folders.v1        # legacy: read once at startup, then superseded
```

Reading a note still accepts `folderId` as `sectionId`, so an older file loads
unchanged. Writes always use the new field.

## Tests

```bash
flutter test                      # widget + unit tests
dart run tool/selfcheck.dart      # 80 assertions on the pure-Dart layer, exit code = result
```

```
test/models/note_test.dart                     # grapheme safety, JSON, sentinels
test/models/note_filter_test.dart              # scopes, sorting, keyword/tag matching
test/models/app_settings_test.dart             # settings round-trip
test/l10n/app_strings_test.dart                # all four bundles carry the same keys
test/data/in_memory_note_repository_test.dart  # CRUD, pin, soft delete, unassign
test/data/in_memory_notebook_repository_test.dart
test/data/shared_prefs_notebook_repository_test.dart  # folders → sections migration
test/utils/markdown_test.dart                  # Markdown → plain text, GFM tables
test/utils/markdown_tools_test.dart            # toolbar edits, wiki-link preprocessing
test/widgets/note_flow_test.dart               # three-pane flow, tabs, autosave, trash,
                                               # wiki-link preview, shortcuts, language switch
```

`tool/selfcheck.dart` exists because the models, filters, text tools and in-memory
repositories are pure Dart: on a machine where `flutter test` cannot start (some
firewalls block the loopback socket the test runner needs, failing with
"Connection closed before test suite loaded"), the logic layer can still be
verified by the plain Dart VM.

### Runtime harness `tool/runtime_harness.dart`

Logic tests do not prove the UI paints. `flutter test` needs the loopback VM
service and `flutter build windows` needs symlink privileges, while `flutter_tester`
needs neither — so the harness boots the real `ArgonoteApp` (in-memory repositories
plus seed data containing CJK punctuation, emoji, ZWJ sequences, a code block, a
GFM table and wiki links) inside `flutter_tester`, drives it with synthesised
pointer events, asserts on the text that is actually on screen at each step, and
writes each state to a PNG through `RepaintBoundary.toImage`.

```bash
flutter build bundle -t tool/runtime_harness.dart      # compile only

"$SDK/bin/cache/artifacts/engine/windows-x64/flutter_tester.exe" \
  --non-interactive --enable-software-rendering \
  --flutter-assets-dir=build/flutter_assets \
  --packages=.dart_tool/package_config.json \
  --icu-data-file-path="$SDK/bin/cache/artifacts/engine/windows-x64/icudtl.dat" \
  build/flutter_assets/kernel_blob.bin
```

- `ARGONOTE_SHOT_DIR` sets the screenshot directory (default `D:/tmp/runtime`).
- Exit code 0 means every assertion passed; failures print one `FAIL …` line each,
  followed by `DONE failures=N`.
- `10_zoom.png` is rendered at a 6× pixel ratio to inspect glyph coverage.
- `ARGONOTE_WIDE=1` runs the desktop three-pane branch. The tester window is a fixed
  800×600 logical pixels, below `HomeShell._wideBreakpoint` (920), so the harness
  overrides `MediaQuery` and `RenderView.configuration` to get a 1440×900 root view.
  Input still goes through the real pipelines (`PlatformDispatcher.onKeyData` with
  `synthesized: true` for `ui.KeyData`), which is what lets this run cover
  `Ctrl+N` / `Ctrl+Tab` / `Ctrl+W`.
- Do not switch it to `TestWidgetsFlutterBinding`: `LiveTestWidgetsFlutterBinding`
  takes over pointer dispatch and the synthesised taps stop landing.
- Afterwards rebuild from the normal entry point (`flutter build bundle`) so
  `build/flutter_assets` does not keep the harness kernel.

## Known issues

- Clicking an `http(s)` link in the preview only reports the target in a snack bar —
  `url_launcher` is deliberately not a dependency. `[[wiki links]]` do navigate, by title.
- Titles are matched case-insensitively for wiki links; duplicate titles resolve to the
  most recently updated note.
- Storage is a single preference document per entity, which is fine for personal notes but
  reloads everything on every write; large libraries would want a real database.
- Windows ships no regional-indicator glyphs in Segoe UI Emoji, so flag emoji render as
  their two letter codes (a China flag shows as `CN`) on Windows desktop; macOS and
  Android are fine. That is a missing system font, not a rendering bug — showing flags
  would mean bundling a font. Family and profession ZWJ sequences do compose correctly,
  confirmed glyph by glyph in the runtime screenshots.
