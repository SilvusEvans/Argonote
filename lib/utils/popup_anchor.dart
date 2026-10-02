import 'package:flutter/widgets.dart';

/// 把 `showMenu` 的矩形贴在锚点控件的下边缘。
///
/// 之前几处菜单是拿整个面板的 context 算坐标（编辑器中心、整棵树底部）或干脆写死
/// 数字，结果菜单飘到屏幕中间/右边。正确做法是拿到触发它的那个小控件的 RenderBox，
/// 用它的左下角到右下角当作矩形：菜单就从控件正下方展开，控件在哪它在哪。
RelativeRect menuRectBelow(BuildContext anchor, {double gap = 4}) {
  final box = anchor.findRenderObject();
  if (box is! RenderBox || !box.hasSize) {
    return RelativeRect.fromLTRB(0, 0, 0, 0);
  }
  final topLeft = box.localToGlobal(Offset.zero);
  final bottom = topLeft.dy + box.size.height;
  return RelativeRect.fromLTRB(
    topLeft.dx,
    bottom + gap,
    topLeft.dx + box.size.width,
    bottom + gap,
  );
}
