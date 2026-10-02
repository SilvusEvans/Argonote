import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/note.dart';
import '../utils/date_format.dart';

/// 列表里的一条笔记（页）。
///
/// 点击打开标签页；右上角弹出动作菜单，回收站视图下自动切换为
/// 「还原 / 彻底删除」。
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    this.sectionLabel,
    this.strings,
    this.onPinToggle,
    this.onTrash,
    this.onRestore,
    this.onDeleteForever,
  });

  final Note note;
  final VoidCallback onTap;

  /// 所属分区的展示名；null 时不显示分区 chip。
  final String? sectionLabel;

  final AppStrings? strings;

  final VoidCallback? onPinToggle;
  final VoidCallback? onTrash;
  final VoidCallback? onRestore;
  final VoidCallback? onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.plainPreview;
    final timeText = formatNoteTime(note.updatedAt);
    final muted = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6);
    final s = strings;

    return ListTile(
      contentPadding: EdgeInsets.only(left: 16, right: note.pinned || s != null ? 44 : 16),
      leading: note.pinned
          ? Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary)
          : null,
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          note.displayTitle.isEmpty && s != null ? s.untitled : note.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  preview.isEmpty ? '—' : preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(timeText, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            ],
          ),
          if (note.tags.isNotEmpty || sectionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (sectionLabel != null)
                    _MetaChip(icon: Icons.book_outlined, label: sectionLabel!),
                  for (final tag in note.tags.take(3))
                    _MetaChip(icon: Icons.label_outline, label: tag),
                ],
              ),
            ),
        ],
      ),
      trailing: s == null
          ? null
          : PopupMenuButton<String>(
              tooltip: s.settings,
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (value) {
                switch (value) {
                  case 'pin':
                    onPinToggle?.call();
                  case 'trash':
                    onTrash?.call();
                  case 'restore':
                    onRestore?.call();
                  case 'forever':
                    onDeleteForever?.call();
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                if (!note.trashed)
                  PopupMenuItem<String>(
                    value: 'pin',
                    child: Row(
                      children: [
                        const Icon(Icons.push_pin_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(note.pinned ? s.unpin : s.pin),
                      ],
                    ),
                  ),
                if (!note.trashed && onTrash != null)
                  PopupMenuItem<String>(
                    value: 'trash',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(s.delete),
                      ],
                    ),
                  ),
                if (note.trashed)
                  PopupMenuItem<String>(
                    value: 'restore',
                    child: Row(
                      children: [
                        const Icon(Icons.restore, size: 18),
                        const SizedBox(width: 8),
                        Text(s.restore),
                      ],
                    ),
                  ),
                if (note.trashed)
                  PopupMenuItem<String>(
                    value: 'forever',
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(s.deleteForever),
                      ],
                    ),
                  ),
              ],
            ),
      onTap: onTap,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
