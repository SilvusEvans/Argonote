import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/note_tab.dart';
import '../models/notebook.dart';
import '../utils/markdown_tools.dart';
import '../utils/popup_anchor.dart';
import '../utils/markdown_plain.dart' show plainTextFromMarkdown;
import 'markdown_view.dart';

/// 单个标签页的编辑器面板：工具栏 + 标题 + 编辑/分栏/预览 + 底部元信息。
///
/// 文本状态全部活在 [NoteTab] 的 controller 里，本组件只持有视图模式等
/// UI 状态；输入变化通过 [onChanged] 通知外壳做脏标记与防抖自动保存。
class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    required this.tab,
    required this.sections,
    required this.notebooks,
    required this.strings,
    required this.onChanged,
    required this.onTogglePin,
    required this.onOpenWikiLink,
  });

  final NoteTab tab;
  final List<Section> sections;
  final List<Notebook> notebooks;
  final AppStrings strings;

  /// 任意输入/元信息变化。
  final VoidCallback onChanged;

  /// 置顶即时落库（不算编辑）。草稿只改内存状态。
  final VoidCallback onTogglePin;

  /// 预览里点击 [[双链]]。
  final void Function(String title) onOpenWikiLink;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  /// 0 = 编辑，1 = 分栏，2 = 预览。
  int _view = 0;

  NoteTab get tab => widget.tab;
  AppStrings get strings => widget.strings;

  void _notify() => widget.onChanged();

  void _apply(EditResult result) {
    final controller = tab.contentController;
    controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.end),
    );
    _notify();
  }

  void _wrap(String before, String after, {String placeholder = ''}) {
    final sel = tab.contentController.selection;
    _apply(wrapSelection(
      tab.contentController.text,
      sel.start.clamp(0, tab.contentController.text.length),
      sel.end.clamp(0, tab.contentController.text.length),
      before: before,
      after: after,
      placeholder: placeholder,
    ));
  }

  void _prefix(String prefix) {
    final sel = tab.contentController.selection;
    _apply(prefixLines(
      tab.contentController.text,
      sel.start.clamp(0, tab.contentController.text.length),
      sel.end.clamp(0, tab.contentController.text.length),
      prefix: prefix,
    ));
  }

  void _insert(String block) {
    final sel = tab.contentController.selection;
    _apply(insertBlock(tab.contentController.text, sel.start, sel.end, block));
  }

  void _copyAsMarkdown() {
    final title = tab.titleController.text.trim();
    final body = tab.contentController.text;
    final markdown = title.isEmpty ? body : '# $title\n\n$body';
    Clipboard.setData(ClipboardData(text: markdown));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(strings.copiedToClipboard), duration: const Duration(seconds: 1)));
  }

  String get _placementLabel {
    var prefix = '';
    for (final notebook in widget.notebooks) {
      if (notebook.id != tab.notebookId) continue;
      prefix = '${notebook.name} / ';
      break;
    }
    final sectionId = tab.sectionId;
    if (sectionId != null) {
      for (final section in widget.sections) {
        if (section.id == sectionId) return '$prefix${section.name}';
      }
    }
    return '$prefix${strings.unsectioned}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = tab.contentController.text;
    final lines = text.isEmpty ? 0 : text.split('\n').length;

    return Column(
      // 不写这行时 Column 默认 center：工具栏和预览这种「按内容取宽」的子项
      // 会被压成固有宽度并水平居中，表现为预览文字莫名靠中间。
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_view != 2) _buildToolbar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('noteTitleField'),
                  controller: tab.titleController,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: strings.titleHint,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => _notify(),
                ),
              ),
              IconButton(
                tooltip: tab.pinned ? strings.unpin : strings.pin,
                icon: Icon(tab.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: widget.onTogglePin,
              ),
              IconButton(
                tooltip: strings.copyMarkdown,
                icon: const Icon(Icons.copy_all_rounded),
                onPressed: _copyAsMarkdown,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (anchorContext) => InkWell(
                    onTap: () => _showSectionPicker(anchorContext),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.book_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _placementLabel,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: 18, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: const StadiumBorder(),
                ),
                showSelectedIcon: false,
                segments: <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 0, icon: const Icon(Icons.edit_outlined, size: 16)),
                  ButtonSegment<int>(value: 1, icon: const Icon(Icons.view_column_outlined, size: 16)),
                  ButtonSegment<int>(value: 2, icon: const Icon(Icons.visibility_outlined, size: 16)),
                ],
                selected: <int>{_view},
                onSelectionChanged: (selection) => setState(() => _view = selection.first),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
        _buildMetaRow(theme, lines),
      ],
    );
  }

  Widget _buildToolbar() {
    final items = <(String, IconData, VoidCallback)>[
      (strings.tbBold, Icons.format_bold, () => _wrap('**', '**', placeholder: '粗体')),
      (strings.tbItalic, Icons.format_italic, () => _wrap('*', '*', placeholder: '斜体')),
      (strings.tbHeading, Icons.title, () => _prefix('## ')),
      (strings.tbList, Icons.format_list_bulleted, () => _prefix('- ')),
      (strings.tbChecklist, Icons.checklist, () => _prefix('- [ ] ')),
      (strings.tbCode, Icons.code, () => _wrap('`', '`', placeholder: 'code')),
      (strings.tbQuote, Icons.format_quote, () => _prefix('> ')),
      (strings.tbLink, Icons.link, () => _wrap('[', '](https://)', placeholder: '文本')),
      (strings.tbTable, Icons.table_chart_outlined, () => _insert(tableBlock)),
      (strings.tbDivider, Icons.horizontal_rule, () => _insert('---')),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          for (final (label, icon, action) in items)
            IconButton(
              tooltip: label,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: action,
              icon: Icon(icon),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final editField = TextField(
      key: const Key('noteContentField'),
      controller: tab.contentController,
      expands: true,
      maxLines: null,
      minLines: null,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
      decoration: InputDecoration(
        hintText: strings.contentHint,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      ),
      onChanged: (_) => _notify(),
    );

    final preview = _buildPreview();

    switch (_view) {
      case 0:
        return editField;
      case 2:
        return preview;
      default:
        return Row(
          children: [
            Expanded(child: editField),
            const VerticalDivider(width: 1),
            Expanded(child: preview),
          ],
        );
    }
  }

  Widget _buildPreview() {
    final source = tab.contentController.text;
    if (plainTextFromMarkdown(source, maxLength: 1).isEmpty) {
      return Center(
        child: Text(
          strings.previewEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: MarkdownView(
        data: applySoftLineBreaks(preprocessWikiLinks(source)),
        onTapLink: (href) {
          final wikiTitle = wikiLinkTarget(href);
          if (wikiTitle != null) {
            widget.onOpenWikiLink(wikiTitle);
            return;
          }
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text('${strings.linkCopiedHint}$href')));
        },
      ),
    );
  }

  /// 底部元信息：标签编辑 + 统计。
  Widget _buildMetaRow(ThemeData theme, int lineCount) {
    final content = tab.contentController.text;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor))),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          Icon(Icons.label_outline, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final tag in tab.tags)
                  Chip(
                    label: Text(tag),
                    labelStyle: theme.textTheme.bodySmall,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: () {
                      tab.tags = tab.tags.where((item) => item != tag).toList();
                      _notify();
                    },
                    deleteIcon: Icon(Icons.close, size: 14, semanticLabel: strings.removeTag),
                  ),
                ActionChip(
                  label: Text(strings.addTag),
                  labelStyle: theme.textTheme.bodySmall,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: _addTag,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${content.characters.length} ${strings.statsChars} · '
            '${_wordCount(content)} ${strings.statsWords} · '
            '$lineCount ${strings.statsLines}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // 与 Note.wordCount 相同口径（对 controller 实时文本计算）。
  static int _wordCount(String text) => text
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .fold<int>(0, (sum, word) {
    final cjk = RegExp('[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]').allMatches(word).length;
    final latin = RegExp(r'[A-Za-z0-9]').hasMatch(word) ? 1 : 0;
    return sum + (cjk > 0 ? cjk : latin);
  });

  Future<void> _addTag() async {
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
    if (value.isEmpty || tab.tags.contains(value)) return;
    tab.tags = <String>[...tab.tags, value];
    _notify();
  }

  /// 归属选择器：笔记本必选，分区可选。
  ///
  /// 菜单项 id 编码为 `nb:<笔记本>` / `s:<分区>`：选笔记本等价于挪到它的
  /// 「未分区」下，选分区则顺带把笔记本一起改掉（笔记不能跨笔记本挂分区）。
  void _showSectionPicker(BuildContext anchor) {
    const notebookPrefix = 'nb:';
    const sectionPrefix = 's:';
    final entries = <PopupMenuEntry<String>>[];
    for (final notebook in widget.notebooks) {
      final unsectioned = notebook.id == tab.notebookId && tab.sectionId == null;
      entries.add(
        PopupMenuItem<String>(
          value: '$notebookPrefix${notebook.id}',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(unsectioned ? Icons.check : Icons.inbox_outlined),
            title: Text('${notebook.name} / ${strings.unsectioned}'),
          ),
        ),
      );
      for (final section in widget.sections.where((s) => s.notebookId == notebook.id)) {
        entries.add(
          PopupMenuItem<String>(
            value: '$sectionPrefix${section.id}',
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 24),
              leading: Icon(section.id == tab.sectionId ? Icons.check : Icons.description_outlined),
              title: Text(section.name),
            ),
          ),
        );
      }
    }

    showMenu<String>(
      context: anchor,
      position: menuRectBelow(anchor),
      items: entries,
    ).then((value) {
      if (value == null) return;
      if (value.startsWith(notebookPrefix)) {
        tab.notebookId = value.substring(notebookPrefix.length);
        tab.sectionId = null;
      } else if (value.startsWith(sectionPrefix)) {
        final sectionId = value.substring(sectionPrefix.length);
        for (final section in widget.sections) {
          if (section.id != sectionId) continue;
          tab.sectionId = sectionId;
          tab.notebookId = section.notebookId;
          break;
        }
      } else {
        return;
      }
      _notify();
    });
  }
}
