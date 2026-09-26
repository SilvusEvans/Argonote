import 'package:flutter/material.dart';

import '../data/folder_repository.dart';
import '../data/note_repository.dart';
import '../l10n/app_strings.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../widgets/markdown_view.dart';

/// 新建 / 编辑笔记页。
///
/// [note] 为 null 时是新建模式，否则是编辑模式。
/// 保存时机有两处：点右上角「保存」，或直接返回（系统返回键 / 左上角返回箭头），
/// 后者由 [PopScope] 拦截后自动保存，避免用户忘记点保存而丢内容。
///
/// 正文支持 Markdown：编辑 / 预览两个分段页签切换，
/// 底部区域负责标签与文件夹归属。
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({
    super.key,
    required this.repository,
    required this.folderRepository,
    this.note,
  });

  final NoteRepository repository;
  final FolderRepository folderRepository;

  /// 为空表示新建。
  final Note? note;

  bool get isNew => note == null;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  List<Folder> _folders = <Folder>[];
  List<String> _tags = <String>[];
  String? _folderId;

  /// 0 = 编辑，1 = Markdown 预览。
  int _tab = 0;
  bool _saving = false;

  static const String _noFolderValue = '__none__';
  static const String _newFolderValue = '__new__';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tags = <String>[...(widget.note?.tags ?? const <String>[])];
    _folderId = widget.note?.folderId;
    _loadFolders();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    final folders = await widget.folderRepository.all();
    if (!mounted) return;
    setState(() => _folders = folders);
  }

  /// 把当前输入落库。
  ///
  /// - 标题、正文、标签、文件夹全为空：不保存；若原本是已有笔记，说明被清空了，直接删除。
  /// - 其余情况：新建走 create，编辑走 update。
  Future<void> _save() async {
    if (_saving) return;
    _saving = true;

    final title = _titleController.text;
    final content = _contentController.text;
    final existing = widget.note;
    final isBlank =
        title.trim().isEmpty && content.trim().isEmpty && _tags.isEmpty && _folderId == null;

    try {
      if (isBlank) {
        if (existing != null) {
          await widget.repository.delete(existing.id);
        }
      } else if (existing == null) {
        await widget.repository.create(
          title: title,
          content: content,
          tags: _tags,
          folderId: _folderId,
        );
      } else {
        await widget.repository.update(
          id: existing.id,
          title: title,
          content: content,
          tags: _tags,
          folderId: _folderId,
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

    if (confirmed ?? false) {
      await widget.repository.delete(note.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _addTag() async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.addTag),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: strings.tagNameHint),
          onSubmitted: (value) => Navigator.of(context).pop(value),
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

    final value = tag?.trim() ?? '';
    if (value.isEmpty) return;
    if (_tags.contains(value)) return;
    setState(() => _tags = <String>[..._tags, value]);
  }

  void _removeTag(String tag) {
    setState(() => _tags = _tags.where((item) => item != tag).toList(growable: false));
  }

  Future<void> _createFolder() async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.newFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: strings.folderNameHint),
          onSubmitted: (value) => Navigator.of(context).pop(value),
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

    final value = name?.trim() ?? '';
    if (value.isEmpty) return;

    final folder = await widget.folderRepository.create(value);
    await _loadFolders();
    if (!mounted) return;
    setState(() => _folderId = folder.id);
  }

  String _currentFolderName(AppStrings strings) {
    for (final folder in _folders) {
      if (folder.id == _folderId) return folder.name;
    }
    return strings.folderNone;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
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
          title: Text(widget.isNew ? strings.createTitle : strings.editTitle),
          actions: [
            if (!widget.isNew)
              IconButton(
                tooltip: strings.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmDelete,
              ),
            // 「保存」做得比常规 TextButton 更大更醒目，仍然保持 MD3 的填充按钮样式。
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              child: FilledButton.icon(
                onPressed: _saveAndPop,
                icon: const Icon(Icons.check_rounded, size: 22),
                label: Text(strings.save),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(112, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: <ButtonSegment<int>>[
                    ButtonSegment<int>(
                      value: 0,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(strings.editTab),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(strings.previewTab),
                    ),
                  ],
                  selected: <int>{_tab},
                  onSelectionChanged: (selection) => setState(() => _tab = selection.first),
                ),
                TextField(
                  key: const Key('noteTitleField'),
                  controller: _titleController,
                  autofocus: widget.isNew,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: strings.titleHint,
                    border: InputBorder.none,
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _buildBody(strings)),
                _buildMetaSection(strings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppStrings strings) {
    if (_tab == 0) {
      return TextField(
        key: const Key('noteContentField'),
        controller: _contentController,
        expands: true,
        maxLines: null,
        minLines: null,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        decoration: InputDecoration(
          hintText: strings.contentHint,
          border: InputBorder.none,
        ),
      );
    }

    final source = _contentController.text;
    if (source.trim().isEmpty) {
      return Center(
        child: Text(
          strings.previewEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.6),
              ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: MarkdownView(
        data: source,
        onTapLink: (href) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text('${strings.linkCopiedHint}$href')));
        },
      ),
    );
  }

  /// 底部固定区：文件夹归属 + 标签编辑。
  Widget _buildMetaSection(AppStrings strings) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(strings.folderLabel),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == _newFolderValue) {
                        await _createFolder();
                      } else if (value == _noFolderValue) {
                        setState(() => _folderId = null);
                      } else {
                        setState(() => _folderId = value);
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: _noFolderValue,
                        child: Text(strings.folderNone),
                      ),
                      for (final folder in _folders)
                        PopupMenuItem<String>(
                          value: folder.id,
                          child: Text(folder.name),
                        ),
                      PopupMenuItem<String>(
                        value: _newFolderValue,
                        child: Row(
                          children: [
                            const Icon(Icons.add, size: 18),
                            const SizedBox(width: 6),
                            Text(strings.newFolder),
                          ],
                        ),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _currentFolderName(strings),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(Icons.label_outline, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(strings.tagsLabel),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tag in _tags)
                      Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onDeleted: () => _removeTag(tag),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 16,
                          semanticLabel: strings.removeTag,
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(strings.addTag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: _addTag,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
