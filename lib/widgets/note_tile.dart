import 'package:flutter/material.dart';

import '../models/note.dart';
import '../utils/date_format.dart';

/// 列表里的一条笔记。抽成独立组件，让列表页只管数据。
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
  });

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.content.trim().replaceAll('\n', ' ');
    final timeText = formatNoteTime(note.updatedAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          note.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              preview.isEmpty ? '暂无内容' : preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
