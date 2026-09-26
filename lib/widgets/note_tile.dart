import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../utils/date_format.dart';

/// 列表里的一条笔记。抽成独立组件，让列表页只管数据。
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    this.folder,
    this.strings,
  });

  final Note note;
  final VoidCallback onTap;

  /// 所属文件夹，用于显示一个小标记；为空表示「未归类」。
  final Folder? folder;

  /// 为空时（比如纯组件预览）不显示本地化文案相关的部分。
  final AppStrings? strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.plainPreview;
    final timeText = formatNoteTime(note.updatedAt);
    final muted = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          note.displayTitle,
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
          if (note.tags.isNotEmpty || folder != null || note.folderId == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (folder != null)
                    _MetaChip(
                      icon: Icons.folder_open_outlined,
                      label: folder!.name,
                    )
                  else if (strings != null)
                    _MetaChip(
                      icon: Icons.folder_off_outlined,
                      label: strings!.folderNone,
                      muted: true,
                    ),
                  for (final tag in note.tags.take(3)) _MetaChip(icon: Icons.label_outline, label: tag),
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
  const _MetaChip({required this.icon, required this.label, this.muted = false});

  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = muted
        ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
        : theme.colorScheme.primary;

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
