import 'package:flutter/material.dart';

import '../data/note_repository.dart';
import '../models/note.dart';
import '../widgets/note_tile.dart';
import 'note_edit_screen.dart';

/// 笔记列表页：展示 + 搜索 + 删除入口 + 新建入口。
///
/// 状态管理刻意保持最简：StatefulWidget + setState。
/// 数据读写全部走 [NoteRepository]，页面不直接接触存储细节。
class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key, required this.repository});

  final NoteRepository repository;

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Note> _notes = <Note>[];
  bool _loading = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _keyword = _searchController.text);
    });
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final notes = await widget.repository.all();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  /// 关键词不区分大小写，标题或正文命中即可。
  List<Note> get _visibleNotes {
    final keyword = _keyword.trim().toLowerCase();
    if (keyword.isEmpty) return _notes;
    return _notes.where((note) {
      return note.title.toLowerCase().contains(keyword) ||
          note.content.toLowerCase().contains(keyword);
    }).toList();
  }

  Future<void> _openEditor(Note? note) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditScreen(repository: widget.repository, note: note),
      ),
    );
    // 编辑页返回后重新拉取，保证列表和最新落库数据一致。
    await _loadNotes();
  }

  /// 删除并提供「撤销」。撤销时把原始笔记（含 id、创建时间）整体还原。
  Future<void> _deleteNote(Note note) async {
    // 先从内存列表里摘掉，保证侧滑动画结束时该条目已从树中移除。
    setState(() => _notes.removeWhere((item) => item.id == note.id));

    await widget.repository.delete(note.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('已删除「${note.displayTitle}」'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              await widget.repository.restore(note);
              await _loadNotes();
            },
          ),
        ),
      );
  }

  /// 只负责弹确认框，返回用户是否确认删除。
  Future<bool> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定删除「${note.displayTitle}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Argonote'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _SearchField(controller: _searchController),
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
        label: const Text('写笔记'),
      ),
    );
  }

  Widget _buildList(List<Note> notes) {
    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88, top: 4),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final note = notes[index];

          // 侧滑删除：Dismissible 负责手势与动画，
          // confirmDismiss 弹确认框，onDismissed 真正落库删除。
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
              onTap: () => _openEditor(note),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索标题或内容',
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

  /// true 表示有笔记但被搜索过滤掉了，false 表示一条笔记都没有。
  final bool hasNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNotes ? Icons.search_off : Icons.note_alt_outlined,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              hasNotes ? '没有匹配的笔记' : '还没有笔记',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasNotes ? '换个关键词试试' : '点击右下角「写笔记」开始第一条',
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
