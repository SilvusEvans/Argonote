import 'package:flutter/material.dart';

import '../data/note_repository.dart';
import '../models/note.dart';

/// 新建 / 编辑笔记页。
///
/// [note] 为 null 时是新建模式，否则是编辑模式。
/// 保存时机有两处：点右上角「保存」，或直接返回（系统返回键 / 左上角返回箭头），
/// 后者由 [PopScope] 拦截后自动保存，避免用户忘记点保存而丢内容。
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({
    super.key,
    required this.repository,
    this.note,
  });

  final NoteRepository repository;

  /// 为空表示新建。
  final Note? note;

  bool get isNew => note == null;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 把当前输入落库。
  ///
  /// - 标题和正文都为空：不保存；若原本是已有笔记，说明被清空了，直接删除。
  /// - 其余情况：新建走 create，编辑走 update。
  Future<void> _save() async {
    if (_saving) return;
    _saving = true;

    final title = _titleController.text;
    final content = _contentController.text;
    final existing = widget.note;

    try {
      if (title.trim().isEmpty && content.trim().isEmpty) {
        if (existing != null) {
          await widget.repository.delete(existing.id);
        }
      } else if (existing == null) {
        await widget.repository.create(title: title, content: content);
      } else {
        await widget.repository.update(
          id: existing.id,
          title: title,
          content: content,
        );
      }
    } finally {
      _saving = false;
    }
  }

  Future<void> _saveAndPop() async {
    await _save();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final note = widget.note;
    if (note == null) return;

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

    if (confirmed ?? false) {
      await widget.repository.delete(note.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<Object?>(
      // 拦截返回手势，先保存再退出。
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNew ? '新建笔记' : '编辑笔记'),
          actions: [
            if (!widget.isNew)
              IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmDelete,
              ),
            TextButton(
              onPressed: _saveAndPop,
              child: const Text('保存'),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  key: const Key('noteTitleField'),
                  controller: _titleController,
                  autofocus: widget.isNew,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: '标题',
                    border: InputBorder.none,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: TextField(
                    key: const Key('noteContentField'),
                    controller: _contentController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    decoration: const InputDecoration(
                      hintText: '写点什么…',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
