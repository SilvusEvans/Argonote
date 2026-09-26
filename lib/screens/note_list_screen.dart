import 'package:flutter/material.dart';

import '../data/folder_repository.dart';
import '../data/note_repository.dart';
import '../l10n/app_strings.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../models/note_filter.dart';
import '../settings/settings_controller.dart';
import '../widgets/filter_bar.dart';
import '../widgets/folder_manager.dart';
import '../widgets/note_tile.dart';
import 'note_edit_screen.dart';
import 'settings_screen.dart';

/// 笔记列表页：展示 + 搜索 + 标签/文件夹筛选 + 删除入口 + 新建入口。
///
/// 状态管理刻意保持最简：StatefulWidget + setState。
/// 数据读写全部走 [NoteRepository] / [FolderRepository]，页面不直接接触存储细节。
class NoteListScreen extends StatefulWidget {
  const NoteListScreen({
    super.key,
    required this.repository,
    required this.folderRepository,
    required this.settingsController,
  });

  final NoteRepository repository;
  final FolderRepository folderRepository;
  final SettingsController settingsController;

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Note> _notes = <Note>[];
  List<Folder> _folders = <Folder>[];
  bool _loading = true;
  NoteFilter _filter = NoteFilter.empty;

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final notes = await widget.repository.all();
    final folders = await widget.folderRepository.all();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _folders = folders;
      _loading = false;
    });
  }

  /// 命中当前筛选条件（关键词 + 文件夹 + 标签）的笔记。
  List<Note> get _visibleNotes =>
      _notes.where(_filter.matches).toList(growable: false);

  Folder? _folderOf(Note note) {
    if (note.folderId == null) return null;
    for (final folder in _folders) {
      if (folder.id == note.folderId) return folder;
    }
    return null;
  }

  Future<void> _openEditor(Note? note) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditScreen(
          repository: widget.repository,
          folderRepository: widget.folderRepository,
          note: note,
        ),
      ),
    );
    // 编辑页返回后重新拉取，保证列表和最新落库数据一致。
    await _load();
  }

  /// 删除并提供「撤销」。撤销时把原始笔记（含 id、创建时间）整体还原。
  Future<void> _deleteNote(Note note) async {
    // 先从内存列表里摘掉，保证侧滑动画结束时该条目已从树中移除。
    setState(() => _notes.removeWhere((item) => item.id == note.id));

    await widget.repository.delete(note.id);
    if (!mounted) return;

    final strings = AppStrings.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.deletedMessage(note.displayTitle)),
          action: SnackBarAction(
            label: strings.undo,
            onPressed: () async {
              await widget.repository.restore(note);
              await _load();
            },
          ),
        ),
      );
  }

  /// 只负责弹确认框，返回用户是否确认删除。
  Future<bool> _confirmDelete(Note note) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteTitle),
        content: Text(strings.deleteMessage(note.displayTitle)),
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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final visible = _visibleNotes;
    final tags = NoteFilter.collectTags(_notes);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: strings.folderSection,
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () => showFolderManager(
              context: context,
              repository: widget.folderRepository,
              strings: strings,
              onChanged: _load,
            ),
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
      body: Column(
        children: [
          _SearchField(controller: _searchController, hint: strings.searchHint),
          FilterBar(
            folders: _folders,
            tags: tags,
            filter: _filter,
            hasUnfiledNotes: _notes.any((note) => note.folderId == null),
            strings: strings,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? _EmptyState(hasNotes: _notes.isNotEmpty)
                    : _buildList(visible),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(null),
        icon: const Icon(Icons.edit_outlined),
        label: Text(strings.newNote),
      ),
    );
  }

  Widget _buildList(List<Note> notes) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88, top: 4),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final note = notes[index];

          // 侧滑删除：Dismissible 负责手势与动画，
          // confirmDismiss 弹二次确认，onDismissed 真正落库删除。
          return Dismissible(
            key: ValueKey<String>(note.id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            confirmDismiss: (_) => _confirmDelete(note),
            onDismissed: (_) {
              _deleteNote(note);
            },
            child: NoteTile(
              note: note,
              folder: _folderOf(note),
              strings: AppStrings.of(context),
              onTap: () => _openEditor(note),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasNotes});

  /// true 表示有笔记但被筛选条件过滤掉了，false 表示一条笔记都没有。
  final bool hasNotes;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNotes ? Icons.filter_alt_off_outlined : Icons.note_alt_outlined,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              hasNotes ? strings.noMatchTitle : strings.emptyTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasNotes ? strings.noMatchSubtitle : strings.emptySubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Icon(
        Icons.delete_outline,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
}
