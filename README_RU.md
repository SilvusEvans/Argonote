[English](./README.md) · [简体中文](./README_ZH.md) · [繁體中文](./README_ZH-TW.md) · [日本語](./README_JA.md) · [日本語（ひらがな）](./README_JA-HIRA.md) · [Français](./README_FR.md) · Русский

# Argonote

Минималистичное приложение для заметок на Flutter: **создание, редактирование, удаление и список** заметок, текст в формате **Markdown**, упорядочивание по **тегам** и **папкам**, **настройки** языка и темы прямо в приложении и **локальное хранение** через `shared_preferences`.

- Фреймворк: Flutter 3.47 / Dart 3.13 (Material 3)
- Платформы: Android / iOS / Windows / macOS / Linux / Web
- Зависимости: `shared_preferences` (хранение), `flutter_markdown_plus` + `markdown` (рендер Markdown), `flutter_localizations` (локализация виджетов)

## Возможности

| Возможность | Описание |
| --- | --- |
| Создание | Кнопка «New note» справа внизу, затем заголовок и текст |
| Редактирование | Нажмите заметку; сохраните кнопкой или просто вернитесь назад (автосохранение) |
| Удаление | **Свайп элемента влево**, подтверждение — и заметки нет; удаление есть и на экране правки |
| Отмена удаления | SnackBar предлагает «Undo» и восстанавливает исходные id и время создания |
| Markdown | Заголовки, списки, блоки кода, ссылки, таблицы, цитаты; вкладки «Edit» / «Preview» |
| Теги | Несколько тегов на заметку; фильтрация списка по тегу |
| Папки | Заметки раскладываются по папкам и фильтруются; папки можно создавать, переименовывать, удалять |
| Поиск | Поле сверху, без учёта регистра по заголовку / тексту / тегам, фильтрация на лету |
| Сортировка | По времени последнего изменения, свежие сверху |
| Автосохранение | Выход с экрана правки (кнопка «назад» / жест) сохраняет всё |
| Язык | Переключение 简体中文 / English / 日本語 / 繁體中文 в настройках; применяется мгновенно и запоминается |
| Цвет темы | 6 основных цветов, а также системная / светлая / тёмная тема |
| Пустые заметки | Заметка без заголовка, текста, тегов и папки не сохраняется; если очистить существующую — она удаляется |

## Структура проекта

```
lib/
├── main.dart                              # Точка входа: инициализирует SharedPreferences, внедряет репозитории
├── app.dart                               # MaterialApp: тема, локаль, локализация, главный экран
├── models/
│   ├── note.dart                          # Модель Note + JSON (чистый Dart, с тегами и папкой)
│   ├── folder.dart                        # Модель Folder
│   ├── note_filter.dart                   # Фильтр (ключевое слово + папка + тег) и логика сопоставления
│   └── app_settings.dart                  # Настройки (язык / цвет / светлая-тёмная тема)
├── data/
│   ├── note_repository.dart               # Интерфейс репозитория заметок
│   ├── shared_prefs_note_repository.dart  # Заметки: реализация на shared_preferences
│   ├── in_memory_note_repository.dart     # Заметки: реализация в памяти (тесты)
│   ├── folder_repository.dart             # Интерфейс репозитория папок
│   ├── shared_prefs_folder_repository.dart
│   ├── in_memory_folder_repository.dart
│   ├── settings_repository.dart           # Интерфейс репозитория настроек
│   ├── shared_prefs_settings_repository.dart
│   └── in_memory_settings_repository.dart
├── settings/
│   └── settings_controller.dart           # ChangeNotifier: изменение → мгновенное применение → сохранение
├── l10n/
│   └── app_strings.dart                   # Таблица строк для четырёх языков
├── screens/
│   ├── note_list_screen.dart              # Список: поиск / фильтры / свайп-удаление / создать / настройки
│   ├── note_edit_screen.dart              # Правка: Markdown и предпросмотр / теги / папка / сохранить
│   └── settings_screen.dart               # Настройки: язык, цвет, оформление (MD3)
├── widgets/
│   ├── note_tile.dart                     # Одна заметка в списке (с тегами и папкой)
│   ├── filter_bar.dart                    # Фильтры по папкам / тегам
│   ├── folder_manager.dart                # Диалог управления папками (создать / переименовать / удалить)
│   └── markdown_view.dart                 # Рендер Markdown (GitHub Flavored)
└── utils/
    ├── date_format.dart                   # Простое форматирование даты
    └── markdown_plain.dart                # Markdown → обычный текст (краткий текст в списке)
```

## Запуск

```bash
flutter pub get
flutter run          # выбрать устройство и запустить
flutter test         # модели / репозитории / фильтры / i18n / Markdown / полный UI-сценарий
flutter analyze      # статический анализ
```

## Языки документации

В репозитории семь README с одинаковым содержанием:

| Файл | Язык |
| --- | --- |
| `README.md` | English (вход по умолчанию) |
| `README_ZH.md` | 简体中文 |
| `README_ZH-TW.md` | 繁體中文 |
| `README_JA.md` | 日本語 |
| `README_JA-HIRA.md` | 日本語（ひらがな） |
| `README_FR.md` | Français |
| `README_RU.md` | Русский |

Переключение: ссылки на языки вверху страницы репозитория или открытие нужного файла локально.
Язык документации **не зависит от языка интерфейса**, который переключается в **Settings → Language** внутри приложения.

## Язык и тема (настройки в приложении)

Нажмите значок шестерёнки справа вверху списка — откроются настройки, три группы элементов Material 3:

- **Язык**: `RadioGroup` + `RadioListTile` для четырёх языков, применяется сразу при выборе
- **Цвет темы**: 6 кружков; нажатие меняет исходный цвет для `ColorScheme.fromSeed`
- **Оформление**: `SegmentedButton` — система / светлая / тёмная

Всё сохраняется в `SharedPreferences` (ключ `argonote.settings.v1`) и восстанавливается при следующем запуске.

```dart
// settings/settings_controller.dart
Future<void> _apply(AppSettings next) async {
  _settings = next;
  notifyListeners();              // интерфейс обновляется сразу
  await _repository.save(next);   // затем сохраняем
}
```

```dart
// app.dart: MaterialApp обёрнут в ListenableBuilder, всё дерево перестраивается при изменении
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

## Поддержка Markdown

`SegmentedButton` сверху экрана правки переключает «Edit» (исходный Markdown) и «Preview».
Рендер — `flutter_markdown_plus` с набором расширений GitHub Flavored: заголовки, списки, списки задач, блоки и inline-код, ссылки, таблицы, цитаты и горизонтальные линии отображаются корректно.

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

Список не рендерит Markdown (слишком тяжело) — `utils/markdown_plain.dart` убирает разметку для краткого текста:

```dart
Note.create(content: '# Title\n\n- first item').plainPreview;   // => 'Title first item'
```

## Теги и папки

```dart
class Note {
  final List<String> tags;   // теги
  final String? folderId;    // папка; null = без папки
}
```

- Внизу экрана правки: папка выбирается через `PopupMenuButton` (включая «Unfiled» и «New folder»), теги добавляются/удаляются через `Chip` + `ActionChip`
- На экране списка: `FilterBar` показывает строку `FilterChip` для папок и строку для тегов; обе комбинируются с ключевым словом
- Логика сопоставления вынесена в `models/note_filter.dart`, поэтому её можно тестировать отдельно:

```dart
const filter = NoteFilter(folderId: 'folder-1', tag: 'work', keyword: 'weekly');
final visible = notes.where(filter.matches).toList();
```

- Удаление папки не удаляет заметки: они показываются как «Unfiled»

## Ключевые места кода

### 1. Модель: только структура, без хранения

`lib/models/note.dart` — чистый Dart без импортов Flutter, поэтому тесты могут свободно создавать объекты и проверять их.

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;   // список сортируется по этому полю по убыванию
  final List<String> tags;
  final String? folderId;

  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();
  String get plainPreview => plainTextFromMarkdown(content);
  bool get isBlank => title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty && folderId == null;

  factory Note.create({String title = '', String content = '', List<String> tags = const [], String? folderId});
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);   // устойчив к отсутствующим / битым данным
}
```

Две детали:

- `displayTitle` приводит пустой заголовок к виду «无标题», поэтому в UI не нужно проверять пустоту.
- `fromJson` использует `DateTime.tryParse` с запасными значениями: **одна битая запись не ломает весь список**, а данные, записанные до появления `tags` / `folderId`, читаются по-прежнему.

### 2. Абстракция репозитория: UI не знает о хранении

```dart
abstract class NoteRepository {
  Future<List<Note>> all();                    // по времени изменения, по убыванию
  Future<Note?> findById(String id);
  Future<Note> create({required String title, required String content,
                       List<String> tags = const [], String? folderId});
  Future<Note> update({required String id, required String title, required String content,
                       required List<String> tags, String? folderId});
  Future<void> delete(String id);
  Future<void> restore(Note note);             // для «отменить»
}
```

`FolderRepository` и `SettingsRepository` устроены так же. Два плюса: смена хранилища (SQLite / Isar / облако) не требует правок UI, а в тестах достаточно подставить реализации в памяти, не мокая платформенные каналы.

### 3. Хранение: один JSON-документ

```dart
static const String storageKey = 'argonote.notes.v1';

Future<void> _writeAll(List<Note> notes) async {
  _sortByUpdatedAtDesc(notes);
  await _prefs.setString(storageKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
```

Ключ содержит версию `v1`, что позволяет делать миграции в будущем. Сортировка выполняется при записи, поэтому чтение остаётся дешёвым.

Ключи хранения:

| Ключ | Содержимое |
| --- | --- |
| `argonote.notes.v1` | Все заметки |
| `argonote.folders.v1` | Все папки |
| `argonote.settings.v1` | Язык / цвет / светлая-тёмная тема |

> Почему не база данных: для записной книжки в несколько сотен заметок с редкими записями один документ проще и удобнее в отладке. Когда объём вырастет — замените на sqflite / isar за тем же интерфейсом.

### 4. Внедрение зависимостей: смена реализации в одной строке

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();       // нужно до await платформенных каналов
  final prefs = await SharedPreferences.getInstance();

  final settingsController = SettingsController(SharedPrefsSettingsRepository(prefs));
  await settingsController.load();                 // восстанавливаем язык / цвет до первого кадра

  runApp(ArgonoteApp(
    repository: SharedPrefsNoteRepository(prefs),
    folderRepository: SharedPrefsFolderRepository(prefs),
    settingsController: settingsController,
  ));
}
```

### 5. Экран списка: поиск, фильтры, свайп для удаления

```dart
List<Note> get _visibleNotes => _notes.where(_filter.matches).toList(growable: false);
```

Удаление через `Dismissible`: `confirmDismiss` запрашивает подтверждение, `onDismissed` действительно удаляет заметку из хранилища.
Затем SnackBar предлагает «Undo», который вызывает `restore(note)` и записывает обратно **исходную запись** — не копию — поэтому сохраняются id и время создания.

```dart
Dismissible(
  key: ValueKey<String>(note.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) => _confirmDelete(note),
  onDismissed: (_) { _deleteNote(note); },
  child: NoteTile(note: note, onTap: () => _openEditor(note)),
)
```

### 6. Экран правки: сохранение при выходе, увеличенная кнопка

```dart
Future<void> _save() async {
  final isBlank = title.trim().isEmpty && content.trim().isEmpty && _tags.isEmpty && _folderId == null;
  if (isBlank) {
    if (existing != null) await widget.repository.delete(existing.id);   // очистили = удалили
  } else if (existing == null) {
    await widget.repository.create(title: title, content: content, tags: _tags, folderId: _folderId);
  } else {
    await widget.repository.update(id: existing.id, title: title, content: content,
                                   tags: _tags, folderId: _folderId);
  }
}
```

Автосохранение при возврате обеспечивает `PopScope`:

```dart
PopScope<Object?>(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _saveAndPop();          // сначала сохранить, потом выйти
  },
  child: Scaffold(...),
)
```

Кнопка сохранения намеренно крупнее и заметнее обычного `TextButton` (мин. 112×48, 17 px, полужирный, иконка галочки), оставаясь при этом заполненной кнопкой MD3 в одном ряду с остальными элементами AppBar:

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

### 7. Локализация: одна таблица и типизированные геттеры

```dart
class AppStrings {
  static AppStrings of(BuildContext context) => forLocale(Localizations.localeOf(context));
  String get newNote => text('newNote');
  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
}
```

Все четыре языка используют один набор ключей (модульный тест проверяет, что каждый ключ есть в каждом языке). Неизвестная локаль откатывается на английский.

### 8. Тесты

```
test/models/note_test.dart                      # сериализация, теги/папка, краткий текст Markdown
test/models/note_filter_test.dart               # комбинации ключевое слово / тег / папка
test/models/app_settings_test.dart              # сериализация настроек, полнота всех языков
test/data/in_memory_note_repository_test.dart   # CRUD заметок + восстановление
test/data/in_memory_folder_repository_test.dart # CRUD папок
test/utils/markdown_test.dart                   # Markdown → текст + разбор GFM (включая таблицы)
test/widgets/note_flow_test.dart                # полный сценарий, поиск, фильтры, предпросмотр Markdown,
                                                # переключение языка из настроек
```

## Известные вопросы

- На Windows (десктоп) Flutter создаёт символические ссылки для плагинов
  (`windows/flutter/ephemeral/.plugin_symlinks`); при `ERROR_INVALID_FUNCTION` включите
  «Режим разработчика» или запустите от имени администратора. Android / iOS / Web это не затрагивает.
- Нажатие ссылки в предпросмотре Markdown показывает URL в SnackBar (`url_launcher` не подключён, приложение само не открывает внешние ссылки).
