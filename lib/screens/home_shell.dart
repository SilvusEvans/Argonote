import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/note_repository.dart';
import '../data/notebook_repository.dart';
import '../l10n/app_strings.dart';
import '../models/note.dart';
import '../models/note_filter.dart';
import '../models/note_tab.dart';
import '../models/notebook.dart';
import '../settings/settings_controller.dart';
import '../utils/popup_anchor.dart';
import '../widgets/note_editor.dart';
import '../widgets/note_tile.dart';
import '../widgets/notebook_tree.dart';
import '../widgets/tab_strip.dart';
import 'settings_screen.dart';

/// 桌面三栏外壳：左笔记本树 / 中页面列表 / 右多标签编辑器。
///
/// 窄屏时树收进 Drawer，列表与编辑器整屏切换。
/// 所有落库动作集中在这里：防抖自动保存、归档、置顶、树节点 CRUD。
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.noteRepository,
    required this.notebookRepository,
    required this.settingsController,
  });

  final NoteRepository noteRepository;
  final NotebookRepository notebookRepository;
  final SettingsController settingsController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, Timer> _saveTimers = <String, Timer>{};
  final Set<String> _savingTabs = <String>{};

  List<Note> _notes = <Note>[];
  List<Notebook> _notebooks = <Notebook>[];
  List<SectionGroup> _groups = <SectionGroup>[];
  List<Section> _sections = <Section>[];
  bool _loading = true;

  NoteScope _scope = NoteScope.all;
  NoteFilter _filter = NoteFilter.empty;

  final List<NoteTab> _tabs = <NoteTab>[];
  String? _activeTabId;
  bool _mobileShowEditor = false;

  static const double _wideBreakpoint = 920;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _filter = _filter.copyWith(keyword: _searchController.text));
    });
    _load();
  }

  @override
  void dispose() {
    for (final timer in _saveTimers.values) {
      timer.cancel();
    }
    for (final tab in _tabs) {
      tab.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.noteRepository.all(),
      widget.notebookRepository.notebooks(),
      widget.notebookRepository.sectionGroups(),
      widget.notebookRepository.sections(),
    ]);
    if (!mounted) return;
    setState(() {
      _notes = results[0] as List<Note>;
      _notebooks = results[1] as List<Notebook>;
      _groups = results[2] as List<SectionGroup>;
      _sections = results[3] as List<Section>;
      _loading = false;
    });
    await _ensureDefaults();
  }

  /// 首次运行（或旧数据迁移后）兜底建出默认笔记本，并修复没有有效归属的笔记。
  ///
  /// 不变式：每条笔记必须归属一个存在的笔记本；分区可选，且必须属于它自己
  /// 所在的那个笔记本。旧数据只有 sectionId（没有 notebookId），这里按分区反推出
  /// 笔记本，尽量保住用户原有的整理结果；分区被删或被跨笔记本移动后留下的
  /// 悬空 sectionId 一律置空，笔记落到该笔记本的「未分区」下。
  ///
  /// 「按分区补笔记本」只改内存（下次保存自然落库），不为一次性迁移再开写接口；
  /// 会丢数据的那两类修复（挪笔记本、清悬空分区）直接落库。
  Future<void> _ensureDefaults() async {
    final strings = AppStrings.of(context);
    final notebooks = _notebooks.isEmpty
        ? [await widget.notebookRepository.createNotebook(strings.defaultNotebook)]
        : _notebooks;
    final fallbackId = notebooks.first.id;

    final validNotebooks = <String>{for (final item in notebooks) item.id};
    final notebookOfSection = <String, String>{
      for (final section in _sections) section.id: section.notebookId,
    };

    final repaired = <String, Note>{};
    final moveToNotebook = <String>[]; // 完全没有笔记本：收进兜底笔记本并清空分区
    final clearSection = <String>[]; // 只需清空分区
    for (final note in _notes) {
      final notebookId = note.notebookId;
      final sectionId = note.sectionId;
      if (notebookId == null || !validNotebooks.contains(notebookId)) {
        final inferred = sectionId == null ? null : notebookOfSection[sectionId];
        if (inferred != null) {
          repaired[note.id] = note.copyWith(notebookId: inferred, updatedAt: note.updatedAt);
        } else {
          moveToNotebook.add(note.id);
          repaired[note.id] =
              note.copyWith(notebookId: fallbackId, sectionId: null, updatedAt: note.updatedAt);
        }
        continue;
      }
      if (sectionId != null && notebookOfSection[sectionId] != notebookId) {
        clearSection.add(note.id);
        repaired[note.id] = note.copyWith(sectionId: null, updatedAt: note.updatedAt);
      }
    }

    if (moveToNotebook.isNotEmpty) {
      await widget.noteRepository.moveNotesToNotebook(moveToNotebook, fallbackId);
    }
    if (clearSection.isNotEmpty) {
      await widget.noteRepository.clearNoteSections(clearSection);
    }
    final isNewInstall = notebooks.length != _notebooks.length;
    if ((!isNewInstall && repaired.isEmpty) || !mounted) return;
    setState(() {
      _notebooks = notebooks;
      _notes = [for (final note in _notes) repaired[note.id] ?? note];
    });
  }

  // ---------------------------------------------------------------- 派生数据

  Set<String> _sectionIdsOfGroup(String groupId) => {
        for (final section in _sections)
          if (section.groupId == groupId) section.id,
      };

  String? _notebookIdOfSection(String sectionId) {
    for (final section in _sections) {
      if (section.id == sectionId) return section.notebookId;
    }
    return null;
  }

  String? _notebookIdOfGroup(String groupId) {
    for (final group in _groups) {
      if (group.id == groupId) return group.notebookId;
    }
    return null;
  }

  Map<String, int> get _sectionCounts {
    final counts = <String, int>{};
    for (final note in _notes) {
      if (note.archived || note.sectionId == null) continue;
      counts[note.sectionId!] = (counts[note.sectionId!] ?? 0) + 1;
    }
    return counts;
  }

  /// 各笔记本「未分区」行下的笔记数。
  Map<String, int> get _unsectionedCounts {
    final counts = <String, int>{};
    for (final note in _notes) {
      if (note.archived || note.sectionId != null) continue;
      final notebookId = note.notebookId;
      if (notebookId == null) continue;
      counts[notebookId] = (counts[notebookId] ?? 0) + 1;
    }
    return counts;
  }

  List<Note> get _visibleNotes => _filter.apply(
        _notes,
        _scope,
        groupSectionIds:
            _scope.kind == NoteScopeKind.group ? _sectionIdsOfGroup(_scope.id!) : null,
      );

  String? _sectionLabelFor(Note note) {
    if (note.sectionId == null) return null;
    for (final section in _sections) {
      if (section.id == note.sectionId) return section.name;
    }
    return null;
  }

  // ---------------------------------------------------------------- 标签页

  NoteTab? get _activeTab {
    for (final tab in _tabs) {
      if (tab.id == _activeTabId) return tab;
    }
    return null;
  }

  void _openNoteTab(Note note) {
    for (final tab in _tabs) {
      if (tab.note?.id == note.id) {
        setState(() {
          _activeTabId = tab.id;
          _mobileShowEditor = true;
        });
        return;
      }
    }
    final tab = NoteTab(id: note.id, note: note);
    tab.fillFromNote(note);
    setState(() {
      _tabs.add(tab);
      _activeTabId = tab.id;
      _mobileShowEditor = true;
    });
  }

  /// 兜底笔记本：树里的第一个笔记本。_ensureDefaults 保证它一定存在。
  String? get _defaultNotebookId => _notebooks.isEmpty ? null : _notebooks.first.id;

  /// 新建笔记的落点：跟随当前范围。笔记本必填；分区只有在「就点在某个分区上」
  /// 时才带上，其余情况留空——即落在该笔记本的「未分区」下。
  (String? notebookId, String? sectionId) get _draftPlacement {
    final id = _scope.id;
    return switch (_scope.kind) {
      NoteScopeKind.section => (_notebookIdOfSection(id!) ?? _defaultNotebookId, id),
      NoteScopeKind.group => (_notebookIdOfGroup(id!), null),
      NoteScopeKind.notebook || NoteScopeKind.unsectioned => (id, null),
      _ => (_defaultNotebookId, null),
    };
  }

  void _newDraftTab() {
    final (notebookId, sectionId) = _draftPlacement;
    final tab = NoteTab(
      id: NoteTab.nextDraftId(),
      notebookId: notebookId,
      sectionId: sectionId,
    );
    setState(() {
      _tabs.add(tab);
      _activeTabId = tab.id;
      _mobileShowEditor = true;
    });
  }

  void _activateTab(NoteTab tab) {
    setState(() => _activeTabId = tab.id);
  }

  Future<void> _closeTab(NoteTab tab) async {
    _saveTimers.remove(tab.id)?.cancel();
    if (tab.dirty) {
      await _saveTab(tab, silent: true);
    }
    if (!mounted) return;
    setState(() {
      final index = _tabs.indexWhere((item) => item.id == tab.id);
      if (index == -1) return;
      _tabs.removeAt(index);
      tab.dispose();
      if (_activeTabId == tab.id) {
        if (_tabs.isEmpty) {
          _activeTabId = null;
          _mobileShowEditor = false;
        } else {
          _activeTabId = _tabs[index.clamp(0, _tabs.length - 1)].id;
        }
      }
    });
  }

  Future<void> _closeAllTabs() async {
    for (final tab in [..._tabs]) {
      await _closeTab(tab);
    }
  }

  Future<void> _closeOtherTabs(NoteTab keep) async {
    for (final tab in [..._tabs]) {
      if (tab.id != keep.id) await _closeTab(tab);
    }
    if (mounted) setState(() => _activeTabId = keep.id);
  }

  void _markDirty(NoteTab tab) {
    tab.dirty = true;
    _saveTimers.remove(tab.id)?.cancel();
    _saveTimers[tab.id] = Timer(const Duration(milliseconds: 800), () {
      _saveTab(tab);
    });
    setState(() {}); // 刷新标签条标题/脏点
  }

  Future<void> _saveTab(NoteTab tab, {bool silent = false}) async {
    if (_savingTabs.contains(tab.id)) return;
    _savingTabs.add(tab.id);
    try {
      final title = tab.titleController.text;
      final content = tab.contentController.text;
      final blank = title.trim().isEmpty && content.trim().isEmpty && tab.tags.isEmpty;

      if (!tab.isPersisted) {
        // 空草稿不落库，避免一堆空白笔记。
        if (blank) return;
        final created = await widget.noteRepository.create(
          title: title,
          content: content,
          tags: tab.tags,
          notebookId: tab.notebookId,
          sectionId: tab.sectionId,
          pinned: tab.pinned,
        );
        tab.note = created;
      } else {
        final id = tab.note!.id;
        if (blank) {
          // 已有笔记被清空：与旧版一致，归档并关闭标签。
          await widget.noteRepository.archiveNote(id);
          tab.dirty = false;
          if (!silent && mounted) await _closeTab(tab);
          return;
        }
        tab.note = await widget.noteRepository.update(
          id: id,
          title: title,
          content: content,
          tags: tab.tags,
          notebookId: tab.notebookId,
          sectionId: tab.sectionId,
        );
      }
      tab.dirty = false;
    } finally {
      _savingTabs.remove(tab.id);
    }
    if (mounted && !silent) await _load();
  }

  Future<void> _togglePin(NoteTab tab) async {
    tab.pinned = !tab.pinned;
    if (tab.isPersisted) {
      await widget.noteRepository.setPinned(tab.note!.id, tab.pinned);
    }
    if (!mounted) return;
    setState(() {});
    await _load();
  }

  // ---------------------------------------------------------------- 笔记动作

  Future<void> _archiveNote(Note note) async {
    await widget.noteRepository.archiveNote(note.id);
    for (final tab in [..._tabs]) {
      if (tab.note?.id == note.id) await _closeTab(tab);
    }
    if (!mounted) return;
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _load();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.archivedMessage(_titleOf(note, strings))),
          action: SnackBarAction(
            label: strings.undo,
            onPressed: () async {
              await widget.noteRepository.unarchiveNote(note.id);
              _load();
            },
          ),
        ),
      );
  }

  String _titleOf(Note note, AppStrings strings) =>
      note.displayTitle.isEmpty ? strings.untitled : note.displayTitle;

  Future<void> _restoreNote(Note note) async {
    await widget.noteRepository.unarchiveNote(note.id);
    await _load();
  }

  Future<void> _deleteForever(Note note) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteForever),
        content: Text(strings.deleteMessage(_titleOf(note, strings))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await widget.noteRepository.delete(note.id);
      for (final tab in [..._tabs]) {
        if (tab.note?.id == note.id) await _closeTab(tab);
      }
      await _load();
    }
  }

  Future<void> _emptyArchive() async {
    final strings = AppStrings.of(context);
    final archived = _notes.where((note) => note.archived).toList();
    if (archived.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.emptyArchive),
        content: Text(strings.emptyArchiveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    for (final note in archived) {
      await widget.noteRepository.delete(note.id);
    }
    await _load();
  }

  Future<void> _togglePinFromList(Note note) async {
    await widget.noteRepository.setPinned(note.id, !note.pinned);
    await _load();
  }

  /// 预览中点击 [[双链]]：找同名笔记开标签，找不到提示。
  void _openWikiLink(String title) {
    final strings = AppStrings.of(context);
    final wanted = title.toLowerCase();
    Note? match;
    for (final note in _notes) {
      if (note.archived) continue;
      if (note.displayTitle.toLowerCase() == wanted) {
        match = note;
        break;
      }
    }
    if (match == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('${strings.wikiLinkNotFound}：$title')));
      return;
    }
    _openNoteTab(match);
  }

  // ---------------------------------------------------------------- 树动作

  Future<String?> _promptName(String title, String hint, {String initial = ''}) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    final name = value?.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  Future<bool> _confirm(String title, String message) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _handleTreeMenu(TreeMenuAction action, Object? node) async {
    final strings = AppStrings.of(context);
    switch (action) {
      case TreeMenuAction.addNotebook:
        final name = await _promptName(strings.newNotebook, strings.notebookNameHint);
        if (name == null) return;
        await widget.notebookRepository.createNotebook(name);
        await _load();
      case TreeMenuAction.addSection:
        final (notebookId, groupId) = switch (node) {
          final Notebook n => (n.id, null),
          final SectionGroup g => (g.notebookId, g.id),
          final Section s => (s.notebookId, s.groupId),
          _ => (_notebooks.isEmpty ? null : _notebooks.first.id, null),
        };
        if (notebookId == null) {
          final name = await _promptName(strings.newNotebook, strings.notebookNameHint);
          if (name == null) return;
          final created = await widget.notebookRepository.createNotebook(name);
          await _addSectionTo(created.id, null);
          return;
        }
        await _addSectionTo(notebookId, groupId);
      case TreeMenuAction.addGroup:
        if (node is! Notebook) return;
        final name = await _promptName(strings.newSectionGroup, strings.groupNameHint);
        if (name == null) return;
        await widget.notebookRepository.createSectionGroup(node.id, name);
        await _load();
      case TreeMenuAction.rename:
        await _renameNode(node);
      case TreeMenuAction.delete:
        await _deleteNode(node);
    }
  }

  Future<void> _addSectionTo(String notebookId, String? groupId) async {
    final strings = AppStrings.of(context);
    final name = await _promptName(strings.newSection, strings.sectionNameHint);
    if (name == null) return;
    await widget.notebookRepository.createSection(notebookId, name, groupId: groupId);
    await _load();
  }

  Future<void> _renameNode(Object? node) async {
    final strings = AppStrings.of(context);
    if (node is Notebook) {
      final name = await _promptName(strings.rename, strings.notebookNameHint, initial: node.name);
      if (name == null) return;
      await widget.notebookRepository.renameNotebook(node.id, name);
    } else if (node is SectionGroup) {
      final name = await _promptName(strings.rename, strings.groupNameHint, initial: node.name);
      if (name == null) return;
      await widget.notebookRepository.renameSectionGroup(node.id, name);
    } else if (node is Section) {
      final name = await _promptName(strings.rename, strings.sectionNameHint, initial: node.name);
      if (name == null) return;
      await widget.notebookRepository.renameSection(node.id, name);
    } else {
      return;
    }
    await _load();
  }

  Future<void> _deleteNode(Object? node) async {
    final strings = AppStrings.of(context);
    if (node is Notebook) {
      if (!await _confirm(strings.deleteNotebookTitle, strings.deleteNotebookMessage)) return;
      final orphans = [for (final note in _notes) if (note.notebookId == node.id) note.id];
      await widget.notebookRepository.deleteNotebook(node.id);
      if (orphans.isNotEmpty) {
        // 笔记本不能没有，所以先兜底出一个再收拢，避免中间态违反不变式。
        final remaining = await widget.notebookRepository.notebooks();
        final target = remaining.isEmpty
            ? await widget.notebookRepository.createNotebook(strings.defaultNotebook)
            : remaining.first;
        await widget.noteRepository.moveNotesToNotebook(orphans, target.id);
      }
      if ((_scope.kind == NoteScopeKind.notebook || _scope.kind == NoteScopeKind.unsectioned) &&
          _scope.id == node.id) {
        _scope = NoteScope.all;
      }
    } else if (node is SectionGroup) {
      if (!await _confirm(strings.deleteGroupTitle, strings.deleteGroupMessage)) return;
      await widget.notebookRepository.deleteSectionGroup(node.id);
      if (_scope.kind == NoteScopeKind.group && _scope.id == node.id) {
        _scope = NoteScope.all;
      }
    } else if (node is Section) {
      if (!await _confirm(strings.deleteSectionTitle, strings.deleteSectionMessage)) return;
      final orphans = [for (final note in _notes) if (note.sectionId == node.id) note.id];
      await widget.notebookRepository.deleteSection(node.id);
      if (orphans.isNotEmpty) {
        await widget.noteRepository.clearNoteSections(orphans);
      }
      if (_scope.kind == NoteScopeKind.section && _scope.id == node.id) {
        _scope = NoteScope.all;
      }
    } else {
      return;
    }
    await _load();
  }

  // ---------------------------------------------------------------- 布局

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= _wideBreakpoint;

    final tree = NotebookTree(
      notebooks: _notebooks,
      groups: _groups,
      sections: _sections,
      sectionCounts: _sectionCounts,
      unsectionedCounts: _unsectionedCounts,
      totalCount: _notes.where((n) => !n.archived).length,
      pinnedCount: _notes.where((n) => !n.archived && n.pinned).length,
      archivedCount: _notes.where((n) => n.archived).length,
      selected: _scope,
      onSelected: (scope) {
        setState(() => _scope = scope);
        if (!wide) {
          _scaffoldKey.currentState?.closeDrawer();
          setState(() => _mobileShowEditor = false);
        }
      },
      onMenu: _handleTreeMenu,
      strings: strings,
    );

    final listPane = _buildListPane(strings, wide);
    final editorPane = _buildEditorPane(strings, wide);

    final shell = Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(strings.appTitle),
        centerTitle: false,
        leading: wide
            ? null
            : _mobileShowEditor
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _mobileShowEditor = false),
                  )
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
        actions: [
          if (!wide && !_mobileShowEditor && _tabs.isNotEmpty)
            IconButton(
              tooltip: strings.editTitle,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _mobileShowEditor = true),
            ),
          IconButton(
            tooltip: strings.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(controller: widget.settingsController),
              ),
            ),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(width: 300, child: SafeArea(child: tree)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : wide
              ? Row(
                  children: [
                    SizedBox(width: 270, child: tree),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 330, child: listPane),
                    const VerticalDivider(width: 1),
                    Expanded(child: editorPane),
                  ],
                )
              : _mobileShowEditor
                  ? editorPane
                  : listPane,
    );

    // CallbackShortcuts 只在"焦点在它的子树里"时才生效，而点列表条目、点分区
    // 这些操作并不会让某个节点拿到焦点（primaryFocus 还停在最外层的 FocusScope），
    // 于是刚打开软件直接按 Ctrl+N/Ctrl+S 是没有反应的。这里在快捷键作用域内部
    // 放一个 autofocus 的锚点节点，保证任何时候都有一段焦点链能走到 bindings；
    // skipTraversal 让它不参与 Tab 遍历，不会打断正常的焦点跳转。
    return CallbackShortcuts(
      bindings: _shortcutBindings(wide: wide),
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        debugLabel: 'shell-keyboard-anchor',
        child: shell,
      ),
    );
  }

  /// 桌面快捷键：新建 / 关闭 / 切换标签页、立即保存。
  Map<ShortcutActivator, void Function()> _shortcutBindings({required bool wide}) {
    void withActive(void Function(NoteTab tab) action) {
      final tab = _activeTab;
      if (tab != null) action(tab);
    }

    return <ShortcutActivator, void Function()>{
      const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newDraftTab,
      const SingleActivator(LogicalKeyboardKey.keyS, control: true):
          () => withActive(_saveTab),
      const SingleActivator(LogicalKeyboardKey.keyW, control: true):
          () => withActive(_closeTab),
      const SingleActivator(LogicalKeyboardKey.tab, control: true):
          () => _cycleTab(1, wide: wide),
      const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true):
          () => _cycleTab(-1, wide: wide),
    };
  }

  /// Ctrl+Tab / Ctrl+Shift+Tab 在标签之间循环，窄屏时顺带切到编辑视图。
  void _cycleTab(int delta, {required bool wide}) {
    if (_tabs.isEmpty) return;
    final current = _activeTab;
    if (current == null) {
      setState(() => _activeTabId = _tabs.first.id);
      return;
    }
    final index = (_tabs.indexOf(current) + delta) % _tabs.length;
    _activateTab(_tabs[index < 0 ? index + _tabs.length : index]);
    if (!wide) setState(() => _mobileShowEditor = true);
  }

  Widget _buildListPane(AppStrings strings, bool wide) {
    final visible = _visibleNotes;
    final tags = NoteFilter.collectTags(_notes.where((n) => !n.archived));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _scopeTitle(strings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Builder(
                builder: (anchorContext) => IconButton(
                  tooltip: strings.sortBy,
                  icon: const Icon(Icons.sort),
                  onPressed: () => _showSortMenu(anchorContext),
                ),
              ),
              if (_scope.kind == NoteScopeKind.archived)
                TextButton(onPressed: _emptyArchive, child: Text(strings.emptyArchive)),
              IconButton(
                tooltip: strings.newNote,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _newDraftTab,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: strings.searchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (tags.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                for (final tag in tags)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(tag),
                      selected: _filter.tag == tag,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (v) =>
                          setState(() => _filter = _filter.copyWith(tag: v ? tag : null)),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? _buildEmptyList(strings)
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final note = visible[index];
                    return NoteTile(
                      note: note,
                      sectionLabel: _sectionLabelFor(note),
                      strings: strings,
                      onTap: () => _openNoteTab(note),
                      onPinToggle: () => _togglePinFromList(note),
                      onArchive: _scope.kind == NoteScopeKind.archived ? null : () => _archiveNote(note),
                      onRestore: () => _restoreNote(note),
                      onDeleteForever: () => _deleteForever(note),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _scopeTitle(AppStrings strings) {
    switch (_scope.kind) {
      case NoteScopeKind.all:
        return strings.allNotes;
      case NoteScopeKind.pinned:
        return strings.pinnedScope;
      case NoteScopeKind.archived:
        return strings.archived;
      case NoteScopeKind.section:
        return _sections.firstWhere((s) => s.id == _scope.id, orElse: () => Section.create(notebookId: '', name: strings.sectionLabel)).name;
      case NoteScopeKind.unsectioned:
        return '${_notebooks.firstWhere((n) => n.id == _scope.id, orElse: () => Notebook.create(strings.notebookLabel)).name} / ${strings.unsectioned}';
      case NoteScopeKind.notebook:
        return _notebooks.firstWhere((n) => n.id == _scope.id, orElse: () => Notebook.create(strings.notebookLabel)).name;
      case NoteScopeKind.group:
        return _groups.firstWhere((g) => g.id == _scope.id, orElse: () => SectionGroup.create('', strings.groupLabel)).name;
    }
  }

  Widget _buildEmptyList(AppStrings strings) {
    final filtered = !_filter.isEmpty;
    final inArchive = _scope.kind == NoteScopeKind.archived;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              inArchive ? Icons.archive_outlined: (filtered ? Icons.filter_alt_off_outlined : Icons.note_alt_outlined),
              size: 56,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              inArchive
                  ? strings.archiveEmpty
                  : filtered
                      ? strings.noMatchTitle
                      : strings.emptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              inArchive ? '' : (filtered ? strings.noMatchSubtitle : strings.emptySubtitle),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext anchor) {
    final strings = AppStrings.of(context);
    showMenu<String>(
      context: context,
      position: menuRectBelow(anchor),
      items: <PopupMenuEntry<String>>[
        for (final sort in NoteSort.values)
          PopupMenuItem<String>(
            value: sort.code,
            child: Row(
              children: [
                Icon(
                  sort == _filter.sort ? Icons.check : Icons.sort,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(switch (sort) {
                  NoteSort.updatedAtDesc => strings.sortUpdated,
                  NoteSort.createdAtDesc => strings.sortCreated,
                  NoteSort.titleAsc => strings.sortTitle,
                }),
              ],
            ),
          ),
      ],
    ).then((code) {
      if (code == null) return;
      setState(() => _filter = _filter.copyWith(sort: NoteSort.fromCode(code)));
    });
  }

  Widget _buildEditorPane(AppStrings strings, bool wide) {
    if (_tabs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(strings.emptySubtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _newDraftTab,
              icon: const Icon(Icons.add),
              label: Text(strings.newNote),
            ),
          ],
        ),
      );
    }

    final active = _activeTab ?? _tabs.first;
    return Column(
      children: [
        TabStrip(
          tabs: _tabs,
          activeId: active.id,
          untitledLabel: strings.untitled,
          closeOthersLabel: strings.tabCloseOthers,
          closeAllLabel: strings.tabCloseAll,
          addNewLabel: strings.newNote,
          onNewDraft: _newDraftTab,
          onSelect: _activateTab,
          onClose: _closeTab,
          onCloseOthers: _closeOtherTabs,
          onCloseAll: _closeAllTabs,
        ),
        Expanded(
          child: IndexedStack(
            index: _tabs.indexOf(active),
            children: [
              for (final tab in _tabs)
                NoteEditor(
                  key: ValueKey<String>(tab.id),
                  tab: tab,
                  sections: _sections,
                  notebooks: _notebooks,
                  strings: strings,
                  onChanged: () => _markDirty(tab),
                  onTogglePin: () => _togglePin(tab),
                  onOpenWikiLink: _openWikiLink,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
