/// 极简时间格式化，避免为了一个日期引入 intl 依赖。
///
/// 规则：
/// - 同一天：HH:mm
/// - 同一年：M月d日
/// - 跨年：yyyy-MM-dd
String formatNoteTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final isSameDay =
      time.year == reference.year && time.month == reference.month && time.day == reference.day;

  if (isSameDay) {
    return '${_two(time.hour)}:${_two(time.minute)}';
  }
  if (time.year == reference.year) {
    return '${time.month}月${time.day}日';
  }
  return '${time.year}-${_two(time.month)}-${_two(time.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
