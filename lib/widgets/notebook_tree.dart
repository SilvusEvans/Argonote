import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/note_filter.dart';
import '../models/notebook.dart';

/// 树上节点菜单动作。node 为 Notebook / SectionGroup / Section，
/// addNotebook 动作时 node 为 null。
enum TreeMenuAction { rename, delete, addSection, addGroup, addNotebook }

/// OneNote 风格左侧树：固定视图 + 笔记本 > 分区组 > 分区。
class NotebookTree extends StatefulWidget {
  const NotebookTree({
    super.key,
    required this.notebooks,
    required this.groups,
    required this.sections,
    required this.sectionCounts,
    required this.totalCount,
    required this.pinnedCount,
    required this.trashCount,
    required this.unfiledCount,
    required this.selected,
    required this.onSelected,
    required this.onMenu,
    required this.strings,
  });

  final List<Notebook> notebooks;
  final List<SectionGroup> groups;
  final List<Section> sections;

  /// sectionId -> 未删除笔记数，用于分区行尾计数。
  final Map<String, int> sectionCounts;

  final int totalCount;
  final int pinnedCount;
  final int trashCount;
  final int unfiledCount;

  final NoteScope selected;
  final ValueChanged<NoteScope> onSelected;
  final void Function(TreeMenuAction action, Object? node) onMenu;

  final AppStrings strings;

  @override
  State<NotebookTree> createState() => _NotebookTreeState();
}

class _NotebookTreeState extends State<NotebookTree> {
  final Set<String> _collapsed = <String>{};

  bool _isSelected(NoteScope scope) {
    if (scope.kind != widget.selected.kind) return false;
    if (scope.kind == NoteScopeKind.section ||
        scope.kind == NoteScopeKind.notebook ||
        scope.kind == NoteScopeKind.group) {
      return scope.id == widget.selected.id;
    }
    return true;
  }

  void _toggle(String id) {
    setState(() {
      if (_collapsed.contains(id)) {
        _collapsed.remove(id);
      } else {
        _collapsed.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        _buildFixedRow(Icons.folder_special_outlined, strings.allNotes, widget.totalCount, NoteScope.all),
        _buildFixedRow(Icons.push_pin_outlined, strings.pinnedScope, widget.pinnedCount, NoteScope.pinned),
        _buildFixedRow(Icons.inbox_outlined, strings.unfiled, widget.unfiledCount, NoteScope.unfiled),
        _buildFixedRow(Icons.delete_outline, strings.trash, widget.trashCount, NoteScope.trash),
        const SizedBox(height: 8),
        for (final notebook in widget.notebooks) ...[
          _buildNodeRow(
            scope: NoteScope.notebook(notebook.id),
            indent: 0,
            icon: Icons.book_outlined,
            label: notebook.name,
            count: _notebookCount(notebook.id),
            expandable: true,
            expanded: !_collapsed.contains(notebook.id),
            onToggle: () => _toggle(notebook.id),
            menuTarget: notebook,
          ),
          if (!_collapsed.contains(notebook.id)) ...[
            for (final section in widget.sections
                .where((s) => s.notebookId == notebook.id && s.groupId == null))
              _buildSectionRow(section, 1),
            for (final group in widget.groups.where((g) => g.notebookId == notebook.id)) ...[
              _buildNodeRow(
                scope: null,
                indent: 1,
                icon: Icons.folder_outlined,
                label: group.name,
                count: null,
                expandable: true,
                expanded: !_collapsed.contains(group.id),
                onToggle: () => _toggle(group.id),
                menuTarget: group,
              ),
              if (!_collapsed.contains(group.id))
                for (final section in widget.sections
                    .where((s) => s.groupId == group.id && s.notebookId == notebook.id))
                  _buildSectionRow(section, 2),
            ],
          ],
        ],
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 16),
          child: TextButton.icon(
            onPressed: () => widget.onMenu(TreeMenuAction.addNotebook, null),
            icon: const Icon(Icons.add, size: 18),
            label: Text(strings.newNotebook),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  int _notebookCount(String notebookId) {
    var count = 0;
    for (final section in widget.sections) {
      if (section.notebookId == notebookId) {
        count += widget.sectionCounts[section.id] ?? 0;
      }
    }
    return count;
  }

  Widget _buildFixedRow(IconData icon, String label, int count, NoteScope scope) {
    return _buildNodeRow(
      scope: scope,
      indent: 0,
      icon: icon,
      label: label,
      count: count,
      expandable: false,
      expanded: false,
      onToggle: null,
      menuTarget: null,
    );
  }

  Widget _buildSectionRow(Section section, double indent) {
    return _buildNodeRow(
      scope: NoteScope.section(section.id),
      indent: indent,
      icon: Icons.description_outlined,
      label: section.name,
      count: widget.sectionCounts[section.id] ?? 0,
      expandable: false,
      expanded: false,
      onToggle: null,
      menuTarget: section,
    );
  }

  Widget _buildNodeRow({
    required NoteScope? scope,
    required double indent,
    required IconData icon,
    required String label,
    required int? count,
    required bool expandable,
    required bool expanded,
    required VoidCallback? onToggle,
    required Object? menuTarget,
  }) {
    final theme = Theme.of(context);
    final selected = scope != null && _isSelected(scope);

    return InkWell(
      onTap: scope != null ? () => widget.onSelected(scope) : onToggle,
      onSecondaryTapDown: menuTarget == null
          ? null
          : (details) => _showRowMenu(details, menuTarget),
      child: Container(
        color: selected ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.55) : null,
        padding: EdgeInsets.only(left: 8 + indent * 16, right: 8),
        height: 34,
        child: Row(
          children: [
            if (expandable)
              IconButton(
                icon: Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 18),
                onPressed: onToggle,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              )
            else
              const SizedBox(width: 22),
            Icon(icon, size: 16, color: selected ? theme.colorScheme.primary : null),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (count != null)
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            if (menuTarget != null)
              IconButton(
                icon: const Icon(Icons.more_vert, size: 16),
                tooltip: widget.strings.settings,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                onPressed: () => _showRowMenuAtButton(target: menuTarget),
              ),
          ],
        ),
      ),
    );
  }

  /// more_vert 按钮点击时借助当前行 BuildContext 定位菜单。
  void _showRowMenuAtButton({required Object target}) {
    final box = context.findRenderObject() as RenderBox?;
    var origin = Offset.zero;
    if (box != null) {
      origin = box.localToGlobal(Offset(box.size.width - 40, box.size.height));
    }
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx, origin.dy),
      items: _menuItems(target),
    );
  }

  void _showRowMenu(TapDownDetails details, Object target) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: _menuItems(target),
    );
  }

  List<PopupMenuEntry<void>> _menuItems(Object target) {
    final strings = widget.strings;
    return <PopupMenuEntry<void>>[
      if (target is Notebook) ...[
        PopupMenuItem<void>(
          onTap: () => widget.onMenu(TreeMenuAction.addSection, target),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add),
            title: Text(strings.newSection),
          ),
        ),
        PopupMenuItem<void>(
          onTap: () => widget.onMenu(TreeMenuAction.addGroup, target),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.create_new_folder),
            title: Text(strings.newSectionGroup),
          ),
        ),
      ],
      if (target is SectionGroup)
        PopupMenuItem<void>(
          onTap: () => widget.onMenu(TreeMenuAction.addSection, target),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add),
            title: Text(strings.newSection),
          ),
        ),
      PopupMenuItem<void>(
        onTap: () => widget.onMenu(TreeMenuAction.rename, target),
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_outlined),
          title: Text(strings.rename),
        ),
      ),
      PopupMenuItem<void>(
        onTap: () => widget.onMenu(TreeMenuAction.delete, target),
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline),
          title: Text(strings.delete),
        ),
      ),
    ];
  }
}
