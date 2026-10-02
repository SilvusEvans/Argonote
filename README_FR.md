[English](./README.md) · [简体中文](./README_ZH.md) · [繁體中文](./README_ZH-TW.md) · [日本語](./README_JA.md) · [日本語（ひらがな）](./README_JA-HIRA.md) · Français · [Русский](./README_RU.md)
> **Doc status / 文档状态:** this translation still describes the v1 folder UI. The app now uses the notebook / section group / section / page hierarchy with multi-tab editing, trash, pinning and wiki links - see [README.md](./README.md) or [README_ZH.md](./README_ZH.md).

# Argonote

Une application de notes minimaliste construite avec Flutter : **créer, éditer, supprimer et lister** des notes, corps de texte en **Markdown**, organisation par **étiquettes** et **dossiers**, **paramètres** intégrés pour la langue et le thème, et **persistance locale** via `shared_preferences`.

- Framework : Flutter 3.47 / Dart 3.13 (Material 3)
- Plateformes : Android / iOS / Windows / macOS / Linux / Web
- Dépendances : `shared_preferences` (stockage), `flutter_markdown_plus` + `markdown` (rendu Markdown), `flutter_localizations` (localisation des widgets)

## Fonctionnalités

| Fonctionnalité | Description |
| --- | --- |
| Créer | Appuyer sur « New note » en bas à droite, puis saisir un titre et un corps |
| Éditer | Appuyer sur une note ; enregistrer avec le bouton ou simplement revenir en arrière (sauvegarde auto) |
| Supprimer | **Glisser un élément vers la gauche**, confirmer, et la note disparaît ; bouton de suppression aussi dans l'écran d'édition |
| Annuler la suppression | Le SnackBar propose « Undo » et restaure l'id et la date de création d'origine |
| Markdown | Titres, listes, blocs de code, liens, tableaux, citations ; onglets « Edit » / « Preview » |
| Étiquettes | Plusieurs étiquettes par note ; filtrage de la liste par étiquette |
| Dossiers | Classement dans des dossiers et filtrage ; création / renommage / suppression des dossiers |
| Recherche | Champ en haut, insensible à la casse sur titre / corps / étiquettes, filtrage en direct |
| Tri | Par date de dernière modification, la plus récente en premier |
| Sauvegarde auto | Quitter l'écran d'édition (bouton retour / geste) enregistre tout |
| Langue | Bascule entre 简体中文 / English / 日本語 / 繁體中文 dans les paramètres ; effet immédiat et mémorisé |
| Couleur du thème | 6 couleurs principales + apparence système / clair / sombre |
| Notes vides | Une note sans titre, corps, étiquette ni dossier n'est pas enregistrée ; vider une note existante la supprime |

## Structure du projet

```
lib/
├── main.dart                              # Point d'entrée : initialise SharedPreferences, injecte les dépôts
├── app.dart                               # MaterialApp : thème, locale, localisation, page d'accueil
├── models/
│   ├── note.dart                          # Modèle Note + JSON (Dart pur, avec étiquettes et dossier)
│   ├── folder.dart                        # Modèle Folder
│   ├── note_filter.dart                   # Filtre (mot-clé + dossier + étiquette) et logique de correspondance
│   └── app_settings.dart                  # Paramètres (langue / couleur / thème clair-sombre)
├── data/
│   ├── note_repository.dart               # Interface du dépôt de notes
│   ├── shared_prefs_note_repository.dart  # Notes : implémentation shared_preferences
│   ├── in_memory_note_repository.dart     # Notes : implémentation en mémoire (tests)
│   ├── folder_repository.dart             # Interface du dépôt de dossiers
│   ├── shared_prefs_folder_repository.dart
│   ├── in_memory_folder_repository.dart
│   ├── settings_repository.dart           # Interface du dépôt de paramètres
│   ├── shared_prefs_settings_repository.dart
│   └── in_memory_settings_repository.dart
├── settings/
│   └── settings_controller.dart           # ChangeNotifier : changement → effet immédiat → persistance
├── l10n/
│   └── app_strings.dart                   # Table de textes pour les quatre langues
├── screens/
│   ├── note_list_screen.dart              # Liste : recherche / filtres / glisser-supprimer / nouveau / paramètres
│   ├── note_edit_screen.dart              # Édition : Markdown + aperçu / étiquettes / dossier / enregistrer
│   └── settings_screen.dart               # Paramètres : langue, couleur, apparence (MD3)
├── widgets/
│   ├── note_tile.dart                     # Une note dans la liste (avec étiquettes et dossier)
│   ├── filter_bar.dart                    # Filtres dossier / étiquette
│   ├── folder_manager.dart                # Dialogue de gestion des dossiers (créer / renommer / supprimer)
│   └── markdown_view.dart                 # Rendu Markdown (GitHub Flavored)
└── utils/
    ├── date_format.dart                   # Formatage de date minimal
    └── markdown_plain.dart                # Markdown → texte brut (résumé de liste)
```

## Démarrage

```bash
flutter pub get
flutter run          # choisir un appareil et lancer
flutter test         # modèles / dépôts / filtres / i18n / Markdown / flux UI complet
flutter analyze      # analyse statique
```

## Langues de la documentation

Le dépôt contient sept README au contenu identique :

| Fichier | Langue |
| --- | --- |
| `README.md` | English (entrée par défaut) |
| `README_ZH.md` | 简体中文 |
| `README_ZH-TW.md` | 繁體中文 |
| `README_JA.md` | 日本語 |
| `README_JA-HIRA.md` | 日本語（ひらがな） |
| `README_FR.md` | Français |
| `README_RU.md` | Русский |

Pour changer de langue, cliquez sur les liens en haut de la page du dépôt, ou ouvrez le fichier localement.
La langue de la documentation est **indépendante de la langue de l'interface**, qui se règle dans **Settings → Language** dans l'application.

## Langue et thème (paramètres dans l'app)

Appuyez sur l'icône engrenage en haut à droite de la liste pour ouvrir les paramètres — trois groupes de contrôles Material 3 :

- **Langue** : `RadioGroup` + `RadioListTile` pour les quatre langues, appliquée dès la sélection
- **Couleur du thème** : 6 pastilles ; un appui change la couleur de graine utilisée par `ColorScheme.fromSeed`
- **Apparence** : `SegmentedButton` pour système / clair / sombre

Tout est écrit dans `SharedPreferences` (clé `argonote.settings.v1`) et restauré au prochain lancement.

```dart
// settings/settings_controller.dart
Future<void> _apply(AppSettings next) async {
  _settings = next;
  notifyListeners();              // l'interface se met à jour immédiatement
  await _repository.save(next);   // puis on persiste
}
```

```dart
// app.dart : MaterialApp enveloppé dans ListenableBuilder, l'arbre entier est reconstruit au changement
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

## Prise en charge de Markdown

Un `SegmentedButton` en haut de l'écran d'édition bascule entre « Edit » (source Markdown) et « Preview ».
Le rendu utilise `flutter_markdown_plus` avec l'extension GitHub Flavored : titres, listes, listes de tâches, code (bloc et en ligne), liens, tableaux, citations et lignes horizontales s'affichent correctement.

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

La liste ne rend pas le Markdown (trop lourd) — `utils/markdown_plain.dart` retire les marqueurs pour le résumé :

```dart
Note.create(content: '# Title\n\n- first item').plainPreview;   // => 'Title first item'
```

## Étiquettes et dossiers

```dart
class Note {
  final List<String> tags;   // étiquettes
  final String? folderId;    // dossier propriétaire ; null = non classé
}
```

- Bas de l'écran d'édition : le dossier se choisit avec `PopupMenuButton` (y compris « Unfiled » et « New folder »), les étiquettes s'ajoutent/retirent avec `Chip` + `ActionChip`
- Écran de liste : `FilterBar` affiche une ligne de `FilterChip` pour les dossiers et une pour les étiquettes ; les deux se combinent avec le mot-clé
- La logique de correspondance est isolée dans `models/note_filter.dart` pour être testable seule :

```dart
const filter = NoteFilter(folderId: 'folder-1', tag: 'work', keyword: 'weekly');
final visible = notes.where(filter.matches).toList();
```

- Supprimer un dossier ne supprime pas les notes : elles apparaissent comme « Unfiled »

## Points clés du code

### 1. Modèle : la structure, pas le stockage

`lib/models/note.dart` est du Dart pur sans import Flutter, les tests peuvent donc construire et vérifier librement.

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;   // la liste est triée par cette date, décroissante
  final List<String> tags;
  final String? folderId;

  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();
  String get plainPreview => plainTextFromMarkdown(content);
  bool get isBlank => title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty && folderId == null;

  factory Note.create({String title = '', String content = '', List<String> tags = const [], String? folderId});
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);   // tolérant aux données manquantes / corrompues
}
```

Deux détails :

- `displayTitle` normalise les titres vides : l'UI n'a jamais à tester le vide.
- `fromJson` utilise `DateTime.tryParse` avec repli : **une donnée corrompue ne casse pas toute la liste**, et les données écrites avant l'existence de `tags` / `folderId` se lisent encore.

### 2. Abstraction du dépôt : l'UI ne touche jamais au stockage

```dart
abstract class NoteRepository {
  Future<List<Note>> all();                    // par date de modification, décroissante
  Future<Note?> findById(String id);
  Future<Note> create({required String title, required String content,
                       List<String> tags = const [], String? folderId});
  Future<Note> update({required String id, required String title, required String content,
                       required List<String> tags, String? folderId});
  Future<void> delete(String id);
  Future<void> restore(Note note);             // utilisé par « annuler »
}
```

`FolderRepository` et `SettingsRepository` suivent la même forme. Deux bénéfices : changer de stockage (SQLite / Isar / cloud) ne demande aucun changement d'UI, et les tests injectent simplement les implémentations en mémoire sans mocker les canaux de plateforme.

### 3. Persistance : un seul document JSON

```dart
static const String storageKey = 'argonote.notes.v1';

Future<void> _writeAll(List<Note> notes) async {
  _sortByUpdatedAtDesc(notes);
  await _prefs.setString(storageKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
```

La clé porte une version `v1` pour permettre des migrations futures. Le tri se fait à l'écriture, la lecture reste peu coûteuse.

Clés de stockage :

| Clé | Contenu |
| --- | --- |
| `argonote.notes.v1` | Toutes les notes |
| `argonote.folders.v1` | Tous les dossiers |
| `argonote.settings.v1` | Langue / couleur / thème clair-sombre |

> Pourquoi pas une base de données : pour un carnet de quelques centaines de notes avec des écritures peu fréquentes, un document unique est plus simple et plus facile à déboguer. Quand le volume grandit, remplacez par sqflite / isar derrière la même interface.

### 4. Injection de dépendances : changer d'implémentation en une ligne

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();       // requis avant d'attendre les canaux de plateforme
  final prefs = await SharedPreferences.getInstance();

  final settingsController = SettingsController(SharedPrefsSettingsRepository(prefs));
  await settingsController.load();                 // restaure langue / couleur avant la première frame

  runApp(ArgonoteApp(
    repository: SharedPrefsNoteRepository(prefs),
    folderRepository: SharedPrefsFolderRepository(prefs),
    settingsController: settingsController,
  ));
}
```

### 5. Écran de liste : recherche, filtres, glisser pour supprimer

```dart
List<Note> get _visibleNotes => _notes.where(_filter.matches).toList(growable: false);
```

La suppression utilise `Dismissible` : `confirmDismiss` demande confirmation, `onDismissed` retire réellement la note du stockage.
Le SnackBar propose alors « Undo », qui appelle `restore(note)` et réécrit l'**enregistrement d'origine** — pas une copie — donc l'id et la date de création sont conservés.

```dart
Dismissible(
  key: ValueKey<String>(note.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) => _confirmDelete(note),
  onDismissed: (_) { _deleteNote(note); },
  child: NoteTile(note: note, onTap: () => _openEditor(note)),
)
```

### 6. Écran d'édition : sauvegarde au retour, bouton plus grand

```dart
Future<void> _save() async {
  final isBlank = title.trim().isEmpty && content.trim().isEmpty && _tags.isEmpty && _folderId == null;
  if (isBlank) {
    if (existing != null) await widget.repository.delete(existing.id);   // vidé = supprimé
  } else if (existing == null) {
    await widget.repository.create(title: title, content: content, tags: _tags, folderId: _folderId);
  } else {
    await widget.repository.update(id: existing.id, title: title, content: content,
                                   tags: _tags, folderId: _folderId);
  }
}
```

La sauvegarde automatique au retour est gérée par `PopScope` :

```dart
PopScope<Object?>(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _saveAndPop();          // sauvegarder puis partir
  },
  child: Scaffold(...),
)
```

Le bouton d'enregistrement est volontairement plus grand et plus visible qu'un simple `TextButton` (min 112×48, 17 px gras, icône de validation), tout en restant un bouton rempli MD3 aligné avec le reste de l'AppBar :

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

### 7. Localisation : une table et des getters typés

```dart
class AppStrings {
  static AppStrings of(BuildContext context) => forLocale(Localizations.localeOf(context));
  String get newNote => text('newNote');
  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
}
```

Les quatre langues partagent le même jeu de clés (un test unitaire vérifie que chaque clé existe dans chaque langue). Toute locale inconnue retombe sur l'anglais.

### 8. Tests

```
test/models/note_test.dart                      # sérialisation, étiquettes/dossier, résumé Markdown
test/models/note_filter_test.dart               # combinaisons mot-clé / étiquette / dossier
test/models/app_settings_test.dart              # sérialisation des paramètres, complétude des langues
test/data/in_memory_note_repository_test.dart   # CRUD notes + restauration
test/data/in_memory_folder_repository_test.dart # CRUD dossiers
test/utils/markdown_test.dart                   # Markdown → texte brut + parsing GFM (tableaux inclus)
test/widgets/note_flow_test.dart                # flux complet, recherche, filtres, aperçu Markdown,
                                                # changement de langue depuis les paramètres
```

## Problèmes connus

- Sur Windows bureau, Flutter crée des liens symboliques pour les plugins
  (`windows/flutter/ephemeral/.plugin_symlinks`) ; `ERROR_INVALID_FUNCTION` signifie qu'il faut
  activer le « Mode développeur » ou lancer en administrateur. Android / iOS / Web ne sont pas concernés.
- Toucher un lien dans l'aperçu Markdown affiche l'URL dans un SnackBar (`url_launcher` n'est pas inclus, l'app n'ouvre jamais de lien externe d'elle-même).
