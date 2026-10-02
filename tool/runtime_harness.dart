// 运行时验证 harness：用 flutter_tester 离屏跑真实的 ArgonoteApp。
//
// 存在的原因：这台机器上 `flutter test` 需要回环 TCP（被防火墙拦）、
// `flutter build windows` 需要符号链接权限（开发者模式未开），
// 于是 UI 层一直只有静态分析和编译级证据。flutter_tester 本身可以在
// 软件光栅化下独立运行，本文件把真实应用装进去，用合成指针事件点按，
// 再把 RepaintBoundary 光栅化成 PNG 落盘，供人眼确认字形/布局真的渲染出来。
//
// 运行方式见 README「跑测试与自检」一节。
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:argonote/app.dart';
import 'package:argonote/data/in_memory_note_repository.dart';
import 'package:argonote/data/in_memory_notebook_repository.dart';
import 'package:argonote/data/in_memory_settings_repository.dart';
import 'package:argonote/l10n/app_strings.dart';
import 'package:argonote/models/app_settings.dart';
import 'package:argonote/models/note.dart';
import 'package:argonote/models/notebook.dart';
import 'package:argonote/settings/settings_controller.dart';
import 'package:argonote/widgets/markdown_view.dart';
import 'package:argonote/widgets/tab_strip.dart';

final GlobalKey _boundaryKey = GlobalKey();
final String _outDir = Platform.environment['ARGONOTE_SHOT_DIR'] ?? 'D:/tmp/runtime';
int _pointerSeq = 10;
final bool _wideMode = Platform.environment['ARGONOTE_WIDE'] == '1';

/// 空库模式：只验证首次运行的兜底建库与归属继承。
final bool _freshMode = Platform.environment['ARGONOTE_FRESH'] == '1';
int _failures = 0;

void _fail(String message) {
  _failures++;
  print('FAIL $message');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory(_outDir).createSync(recursive: true);

  // 兜底：帧调度、光栅化任何一步卡住都别把进程挂在那儿。
  Timer(const Duration(seconds: 150), () {
    print('WATCHDOG 150s elapsed, _failures=$_failures');
    exit(2);
  });

  final now = DateTime.now();
  final DateTime t0 = DateTime(2026, 1, 5, 9, 30);
  final notebooks = <Notebook>[
    Notebook(id: 'nb-work', name: '工作笔记本', createdAt: t0),
    Notebook(id: 'nb-personal', name: 'Personal 🌍', createdAt: t0),
  ];
  final groups = <SectionGroup>[
    SectionGroup(id: 'g-2026', notebookId: 'nb-work', name: '2026 计划', createdAt: t0),
  ];
  final sections = <Section>[
    Section(id: 's-standup', notebookId: 'nb-work', groupId: 'g-2026', name: '周会', createdAt: t0),
    Section(id: 's-ideas', notebookId: 'nb-work', name: '随想', createdAt: t0),
    Section(id: 's-reading', notebookId: 'nb-personal', name: '读书笔记', createdAt: t0),
  ];
  final notes = <Note>[
    Note(
      id: 'n-1',
      title: '周会纪要 · 字符回归测试',
      content: '# 标题\n\n中文标点：「引号」「书名号」——破折号…\n\n'
          'Emoji：👨‍👩‍👧‍👑 家庭 / 🇨🇳 国旗 / 👨🏽‍💻 职业+肤色\n\n'
          '```dart\nfinal 列表 = <String>[\'α β γ\', \'你好，世界\'];\nprint(列表);\n```\n\n'
          '| 名称 | 说明 |\n|---|---|\n| 甲 | 第一行 |\n| 乙 | 第二行 |\n\n'
          '> 引用块第一行\n> 引用块第二行\n\n'
          '行内 `code` 与 **粗体**，下面是单换行：\n紧接着的这一行\n\n'
          '- 列表甲\n- 列表乙\n\n'
          '1. 有序一\n2. 有序二\n\n'
          '---\n\n'
          '双链：[[另一页]] 与 [链接](https://example.com)\n',
      createdAt: now,
      updatedAt: now,
      tags: <String>['测试', '中文'],
      notebookId: 'nb-work',
      sectionId: 's-standup',
      pinned: true,
    ),
    Note(
      id: 'n-2',
      title: '另一页',
      content: '被 [[周会纪要 · 字符回归测试]] 引用的页面。\n\n- 列表项\n- 第二项 🎉\n',
      createdAt: now,
      updatedAt: now,
      notebookId: 'nb-work',
      sectionId: 's-standup',
    ),
    Note(
      id: 'n-3',
      title: '零散想法',
      content: '这条笔记只有笔记本、没有分区，应当出现在「未分区」行下。',
      createdAt: now,
      updatedAt: now,
      notebookId: 'nb-work',
    ),
    Note(
      id: 'n-4',
      title: '待清理',
      content: '归档里的页面，默认列表不该看到它。',
      createdAt: now,
      updatedAt: now,
      notebookId: 'nb-work',
      sectionId: 's-ideas',
      archived: true,
      deletedAt: now,
    ),
  ];

  final settingsController = SettingsController(InMemorySettingsRepository());

  // 出厂默认语言现在是英文，而下面的断言全部写的是中文文案，
  // 所以显式切回简体中文；默认语言本身由 _drive 开头的专项检查负责。
  await settingsController.setLanguage(AppLanguage.simplifiedChinese);
  if (AppSettings.defaults().language != AppLanguage.english) {
    _fail('出厂默认语言应为英文');
  }

  if (_freshMode) {
    // 空库：什么都没有了，看应用会不会自己建出默认笔记本。
    notebooks.clear();
    groups.clear();
    sections.clear();
    notes.clear();
  }

  final Widget app = RepaintBoundary(
    key: _boundaryKey,
    child: ArgonoteApp(
      noteRepository: InMemoryNoteRepository(notes),
      notebookRepository: InMemoryNotebookRepository(notebooks: notebooks, groups: groups, sections: sections),
      settingsController: settingsController,
    ),
  );

  runApp(_wideMode ? _fakeWideMediaQuery(app) : app);

  unawaited(_drive(settingsController));
}

/// 桌面三栏目标尺寸（逻辑像素）。
const Size _wideLogicalSize = Size(1440, 900);

/// 覆盖根 MediaQuery 的 size，让 `MediaQuery.sizeOf` 的断点判定走进三栏分支。
///
/// 断点在 home_shell 里读的是 MediaQuery，而 flutter_tester 的窗口固定
/// 800×600 逻辑像素（2400×1800 物理 / dpr 3.0），低于 _wideBreakpoint(920)。
/// 渲染约束本身由 [_forceWideLayout] 直接改 RenderView.configuration。
Widget _fakeWideMediaQuery(Widget child) {
  return Builder(
    builder: (BuildContext context) {
      final view = ui.PlatformDispatcher.instance.implicitView;
      final base = MediaQuery.maybeOf(context) ??
          MediaQueryData.fromView(view ?? ui.PlatformDispatcher.instance.implicitView!);
      return MediaQuery(data: base.copyWith(size: _wideLogicalSize), child: child);
    },
  );
}

/// 等出帧：post-frame 回调 + 主动 request，避免没有脏 widget 时永远等不到。
Future<void> _frames([int count = 4]) async {
  for (var i = 0; i < count; i++) {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    WidgetsBinding.instance.scheduleFrame();
    await completer.future.timeout(const Duration(seconds: 8), onTimeout: () {});
  }
}

List<Element> _allElements() {
  final out = <Element>[];
  void visit(Element element) {
    out.add(element);
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return out;
}

void _reportView(String tag) {
  final view = ui.PlatformDispatcher.instance.implicitView;
  final renderObject = _boundaryKey.currentContext?.findRenderObject();
  final size = (renderObject is RenderBox && renderObject.hasSize)
      ? renderObject.size
      : null;
  print('VIEW $tag physical=${view?.physicalSize} dpr=${view?.devicePixelRatio} '
      'logical=${view == null ? null : view.physicalSize / view.devicePixelRatio} '
      'boundary=$size');
}

void _dumpTexts(String tag) {
  final texts = <String>[];
  for (final element in _allElements()) {
    final widget = element.widget;
    if (widget is Text && widget.data != null && widget.data!.trim().isNotEmpty) {
      texts.add(widget.data!.trim());
    }
  }
  print('TEXTS[$tag] (${texts.length}) ${texts.join(' | ')}');
}

/// 断言界面上确实出现了某段文字。
void _expectText(String needle, String what) {
  for (final element in _allElements()) {
    final widget = element.widget;
    if (widget is Text && (widget.data?.contains(needle) ?? false)) return;
  }
  _fail('$what: 界面上找不到「$needle」');
}

Element? _textElement(String needle) {
  Element? best;
  int bestLength = 1 << 30;
  double bestArea = double.infinity;
  for (final element in _allElements()) {
    final widget = element.widget;
    if (widget is! Text || widget.data == null) continue;
    if (!widget.data!.contains(needle)) continue;
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    // 优先最短的那段文字：列表里标题短、摘要长，避免点到摘要。
    final length = widget.data!.length;
    final area = box.size.width * box.size.height;
    if (length < bestLength || (length == bestLength && area < bestArea)) {
      bestLength = length;
      bestArea = area;
      best = element;
    }
  }
  return best;
}

Element? _iconElement(IconData icon) {
  for (final element in _allElements()) {
    final widget = element.widget;
    if (widget is Icon && widget.icon == icon) return element;
    if (widget is IconButton && widget.icon is Icon && (widget.icon as Icon).icon == icon) return element;
  }
  return null;
}

Offset _centerOf(Element element) {
  final box = element.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) + box.size.center(Offset.zero);
}

/// 打印当前焦点节点到根的祖先链，用来判断焦点是否落在 CallbackShortcuts 之内。
void _focusDiag(String tag) {
  final focus = FocusManager.instance.primaryFocus;
  final context = focus?.context;
  if (focus == null || context is! Element) {
    print('FOCUS[$tag] ${focus == null ? '无焦点' : '焦点 context 不是 Element'}');
    return;
  }
  final chain = <String>['${focus.debugLabel ?? ''}(${context.widget.runtimeType})'];
  context.visitAncestorElements((Element ancestor) {
    chain.add(ancestor.widget.runtimeType.toString());
    return chain.length < 45;
  });
  print('FOCUS[$tag] ${chain.join('<')}');
}

/// 等真实动画（抽屉 250ms、页面切换 300ms）跑完。
Future<void> _settle({int frames = 28}) async {
  await Future<void>.delayed(const Duration(milliseconds: 60));
  await _frames(frames);
}

Future<void> _tapElement(Element? element, String label) async {
  if (element == null) {
    _fail('tap $label: 没找到目标');
    return;
  }
  final box = element.renderObject;
  if (box is! RenderBox || !box.attached || !box.hasSize) {
    _fail('tap $label: 没有渲染尺寸');
    return;
  }
  try {
    await Scrollable.ensureVisible(element, duration: Duration.zero)
        .timeout(const Duration(seconds: 5));
  } catch (error) {
    print('SCROLL-SKIP $label: $error');
  }
  await _frames(2);
  final position = _centerOf(element);
  final view = ui.PlatformDispatcher.instance.implicitView?.viewId ?? 0;
  final binding = WidgetsBinding.instance;
  binding.handlePointerEvent(PointerEnterEvent(pointer: _pointerSeq, viewId: view, position: position));
  binding.handlePointerEvent(
      PointerDownEvent(pointer: _pointerSeq, viewId: view, position: position, kind: PointerDeviceKind.mouse));
  await _frames(1);
  binding.handlePointerEvent(PointerUpEvent(pointer: _pointerSeq, viewId: view, position: position));
  _pointerSeq++;
  await _settle();
  print('TAP $label @ $position');
}

Future<void> _tapText(String needle, String label) => _tapElement(_textElement(needle), label);
Future<void> _tapIcon(IconData icon, String label) => _tapElement(_iconElement(icon), label);

Future<void> _shot(String name, {double? pixelRatioOverride}) async {
  final context = _boundaryKey.currentContext;
  final boundary = context?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    _fail('shot $name: 拿不到 RepaintBoundary（${boundary.runtimeType}）');
    return;
  }
  final ratio = pixelRatioOverride ??
      (ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0).clamp(1.0, 2.0);
  final image = await boundary.toImage(pixelRatio: ratio);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    _fail('shot $name: toByteData 返回 null');
    return;
  }
  final file = File('$_outDir/$name.png');
  file.writeAsBytesSync(Uint8List.fromList(bytes.buffer.asUint8List()));
  print('SHOT ${file.path} ${boundary.size} ratio=$ratio bytes=${bytes.lengthInBytes}');
  image.dispose();
}

/// 当前标签条上的标签数（-1 表示标签条没渲染）。
int _tabCount() {
  for (final element in _allElements()) {
    final widget = element.widget;
    if (widget is TabStrip) return widget.tabs.length;
  }
  return -1;
}

/// 标签条里每个标签胶囊的实际宽度，用于验证宽度确实跟着标题走。
List<double> _tabWidths() {
  final widths = <double>[];
  for (final element in _allElements()) {
    if (element.widget is! AnimatedContainer) continue;
    var underTabStrip = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is! TabStrip) return true;
      underTabStrip = true;
      return false;
    });
    if (!underTabStrip) continue;
    final box = element.renderObject;
    if (box is RenderBox && box.hasSize) widths.add(box.size.width);
  }
  return widths;
}

/// 预览正文必须真的撑满所在容器的宽度。
///
/// 踩过的坑：NoteEditor 外层 Column 漏写 crossAxisAlignment，默认的 center
/// 会把「按内容取宽」的预览整块漂到中间，看起来像文字自动居中。
/// 三栏下预览本来就不从窗口 0 点开始，所以只能相对外层容器判定。
void _expectPreviewStretched(String what) {
  for (final element in _allElements()) {
    if (element.widget is! MarkdownView) continue;
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) {
      _fail('$what: 预览没有渲染尺寸');
      return;
    }
    RenderBox? host;
    element.visitAncestorElements((ancestor) {
      final render = ancestor.renderObject;
      if (render is RenderBox && render.hasSize && render != box) {
        host = render;
        return false;
      }
      return true;
    });
    final hostBox = host;
    if (hostBox == null) {
      _fail('$what: 找不到预览的外层容器');
      return;
    }
    final inset = box.localToGlobal(Offset.zero).dx - hostBox.localToGlobal(Offset.zero).dx;
    final slack = hostBox.size.width - box.size.width;
    print('PREVIEW $what inset=${inset.toStringAsFixed(1)} '
        'width=${box.size.width.toStringAsFixed(1)} host=${hostBox.size.width.toStringAsFixed(1)}');
    if (inset > 40) _fail('$what: 预览左边距 ${inset.toStringAsFixed(1)}，被水平居中了');
    if (slack > 80) _fail('$what: 预览比容器窄 ${slack.toStringAsFixed(0)}px，没撑开');
    return;
  }
  _fail('$what: 界面上找不到预览内容');
}

void _expectNoText(String needle, String what) {
  for (final element in _allElements()) {
    final widget = element.widget;
    if (widget is Text && (widget.data?.contains(needle) ?? false)) {
      _fail('$what: 「$needle」不该出现');
      return;
    }
  }
}

Future<void> _drive(SettingsController settingsController) async {
  if (_freshMode) {
    await _driveFresh();
    print('DONE failures=$_failures');
    exit(_failures == 0 ? 0 : 1);
  }
  if (_wideMode) {
    await _driveWide(settingsController);
    print('DONE failures=$_failures');
    exit(_failures == 0 ? 0 : 1);
  }
  await _settle();
  _reportView('initial');

  // A. 默认列表：所有笔记，归档里的不出现
  _dumpTexts('list');
  _expectText('所有笔记', '默认范围标题');
  _expectText('周会纪要', '列表里的置顶笔记');
  _expectNoText('待清理', '归档隔离');
  await _shot('01_list');

  // B. 抽屉里的笔记本树：笔记本 > 分区组 > 分区 三层
  await _tapIcon(Icons.menu, '打开抽屉');
  _expectText('工作笔记本', '笔记本节点');
  _expectText('Personal', '第二个笔记本');
  _expectText('2026 计划', '分区组节点');
  _expectText('读书笔记', '另一个笔记本下的分区');
  _expectText('未分区', '每个笔记本下的未分区行');
  _expectNoText('未分组', '未分组入口已取消');
  await _shot('02_tree');

  // C. 选分区 → 抽屉收起，列表按分区筛选
  await _tapText('周会', '分区「周会」');
  _expectText('周会纪要', '分区筛选结果');
  _expectNoText('零散想法', '分区筛选不含未分区笔记');

  // C2. 选「未分区」→ 只看该笔记本下没分区的笔记
  await _tapIcon(Icons.menu, '再次打开抽屉');
  await _tapText('未分区', '未分区行');
  _expectText('零散想法', '未分区范围');
  _expectNoText('周会纪要', '未分区范围排除有分区的笔记');
  await _shot('03_unsectioned');

  await _tapIcon(Icons.menu, '回到未分区列表');
  await _tapText('周会', '回到分区「周会」');
  await _shot('03_filtered');

  // D. 打开笔记 → 编辑器 + 归属面包屑 + 单标签
  await _tapText('周会纪要', '笔记条目');
  await _settle();
  _expectText('工作笔记本 / 周会', '面包屑');
  if (_tabCount() != 1) _fail('打开笔记后标签数应为 1，实际 ${_tabCount()}');
  await _shot('04_editor');

  // D2. 归属选择器：笔记本必填、分区可选，选分区时笔记本跟着走。
  //     此时抽屉已收起，同名的树节点不在树上，菜单项是唯一命中。
  await _tapText('工作笔记本 / 周会', '面包屑打开归属菜单');
  await _settle(frames: 6);
  _expectText('Personal 🌍 / 未分区', '归属菜单列出别的笔记本');
  await _tapText('随想', '归属菜单里的另一个分区');
  await _settle(frames: 6);
  _expectText('工作笔记本 / 随想', '换分区后的面包屑');
  _expectNoText('工作笔记本 / 周会', '旧归属残留');
  await _shot('04b_picker');
  await _tapText('工作笔记本 / 随想', '再次打开归属菜单');
  await _settle(frames: 6);
  await _tapText('周会', '改回原分区');
  await _settle(frames: 6);
  _expectText('工作笔记本 / 周会', '归属改回原状');

  // E. Markdown 预览模式
  await _tapIcon(Icons.visibility_outlined, '预览');
  await _settle();
  _dumpTexts('preview');
  _expectPreviewStretched('纯预览排版');
  await _shot('05_preview');

  // F. 新建标签 → 两个标签并存
  await _tapIcon(Icons.add, '新建标签');
  if (_tabCount() != 2) _fail('新建后标签数应为 2，实际 ${_tabCount()}');
  final widths = _tabWidths();
  print('TAB-WIDTHS ${widths.map((w) => w.toStringAsFixed(1)).join(' , ')}');
  if (widths.length != 2) {
    _fail('量不到 2 个标签的宽度，实际 ${widths.length}');
  } else if ((widths.first - widths.last).abs() < 40) {
    _fail('长短标题的标签宽度几乎一样（${widths.map((w) => w.toStringAsFixed(1)).join(' / ')}），说明标签没有随标题自适应');
  }
  await _shot('06_two_tabs');

  // G. 关闭当前标签 → 回到一个
  await _tapIcon(Icons.close, '关闭标签');
  if (_tabCount() != 1) _fail('关闭后标签数应为 1，实际 ${_tabCount()}');
  await _shot('07_one_tab');

  // H. 设置页：深色模式
  await _tapIcon(Icons.settings_outlined, '设置');
  _expectText('设置', '设置页标题');
  _expectText('界面语言', '语言分区');
  await _tapText('深色', '深色模式');
  await _settle();
  if (settingsController.settings.themeMode != ThemeMode.dark) {
    _fail('themeMode 未变成 dark（${settingsController.settings.themeMode}）');
  }
  await _shot('08_dark');

  // I. 切换界面语言 → 文案立刻变英文
  await _tapText('English', '语言单选');
  await _settle();
  _expectText('Settings', '设置页英文标题');
  // 提示条得跟着新语言，否则切完英文还弹中文。
  _expectText('Settings saved and applied', '切换语言后的确认条');
  _expectNoText('设置已保存并生效', '确认条残留旧语言');
  await _shot('09_english_dark');
  print('SETTINGS locale=${settingsController.settings.locale} '
      'themeMode=${settingsController.settings.themeMode}');

  // J. 回列表重新打开那篇带 emoji 的笔记，切预览后用 6 倍率截图逐字看字形
  await _tapIcon(Icons.arrow_back, '返回主界面');
  await _tapIcon(Icons.arrow_back, '回到列表');
  await _tapText('周会纪要', '重新打开笔记');
  await _tapIcon(Icons.visibility_outlined, '预览（放大截图前）');
  _expectPreviewStretched('英文界面下的预览排版');
  await _shot('10_zoom', pixelRatioOverride: 6);

  print('DONE failures=$_failures');
  exit(_failures == 0 ? 0 : 1);
}

// ---- 桌面三栏分支 ----

/// 真正把根渲染视图撑到 1440×900 逻辑像素。
///
/// 必须在 runApp 之后调用（那时 renderViews 才建好）。直接改
/// RenderView.configuration 是因为 `ViewConfiguration.fromView` 读的是
/// `view.physicalConstraints`，而 flutter_tester 的真实窗口是
/// 2400×1800 物理 / dpr 3.0 = 800×600 逻辑，够不到 home_shell 的
/// _wideBreakpoint(920)。引擎侧画布比这更大，合成 1440×900 不会被裁。
Future<void> _forceWideLayout() async {
  final binding = WidgetsBinding.instance;
  if (binding.renderViews.isEmpty) {
    _fail('runApp 之后仍然没有 RenderView，撑不宽窗口');
    return;
  }
  for (final renderView in binding.renderViews) {
    renderView.configuration = ViewConfiguration(
      physicalConstraints: BoxConstraints.tight(_wideLogicalSize),
      logicalConstraints: BoxConstraints.tight(_wideLogicalSize),
      devicePixelRatio: 1.0,
    );
  }
  binding.scheduleForcedFrame();
  await _frames(10);
  final size = binding.renderViews.first.configuration.logicalConstraints.biggest;
  print('WIDE-LAYOUT root=$size');
  if (size.width < 920) _fail('根视图宽度还是 $size，进不了三栏分支');
}

/// 当前激活标签的标识：草稿标题为空，只能退回用 id 区分。
String? _activeTabTitle() {
  for (final element in _allElements()) {
    final widget = element.widget;
    if (widget is TabStrip) {
      for (final tab in widget.tabs) {
        if (tab.id == widget.activeId) {
          final label = tab.label;
          return label.isEmpty ? tab.id : label;
        }
      }
    }
  }
  return null;
}

int _keySeq = 0;
bool _keyProbeInstalled = false;

/// 在 HardwareKeyboard 上挂一个观察者，打印框架真正收到的 KeyEvent。
/// 只为定位快捷键为什么没命中，返回 false 不影响正常派发。
void _installKeyProbe() {
  if (_keyProbeInstalled) return;
  _keyProbeInstalled = true;
  HardwareKeyboard.instance.addHandler((KeyEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    print('KEY ${event.runtimeType} '
        'logical=${event.logicalKey.keyLabel} '
        'ctrl=${HardwareKeyboard.instance.isControlPressed} '
        'focus=${focus?.context.runtimeType}');
    return false;
  });
}

/// 注入 Ctrl + 某个键，走真实 KeyEvent 管线，能命中 CallbackShortcuts。
///
/// 注入点只能是 `PlatformDispatcher.onKeyData`（ServicesBinding 把它接到
/// KeyEventManager）：`HardwareKeyboard.handleKeyData` 与 `KeyEventManager`
/// 都不是公开 API。`synthesized: true` 会让 KeyEventManager 立刻把这个事件
/// 派发成一条独立的 KeyMessage 给 FocusManager —— 否则非合成事件会被缓存，
/// 等一条 RawKeyEvent 到来才 flush，而这条注入路径永远不会有 RawKey。
/// 返回值只能表示"派发过程没抛异常"，快捷键到底生效要看副作用（标签数等）。
Future<void> _pressCtrl(PhysicalKeyboardKey physical, LogicalKeyboardKey logical) async {
  _installKeyProbe();
  final handler = ui.PlatformDispatcher.instance.onKeyData;
  if (handler == null) {
    _fail('onKeyData 尚未安装（syncKeyboardState 没返回），键盘事件注入不了');
    return;
  }
  bool send(int ph, int lo, ui.KeyEventType type) {
    _keySeq++;
    try {
      handler(ui.KeyData(
        timeStamp: Duration(milliseconds: _keySeq * 8),
        type: type,
        physical: ph,
        logical: lo,
        character: null,
        synthesized: true,
      ));
      return true;
    } catch (error, stack) {
      print('KEYERR $error\n$stack');
      return false;
    }
  }

  final ctrlPh = PhysicalKeyboardKey.controlLeft.usbHidUsage;
  final ctrlLo = LogicalKeyboardKey.controlLeft.keyId;
  final results = <bool>[];
  results.add(send(ctrlPh, ctrlLo, ui.KeyEventType.down));
  print('AFTER-CTRL-DOWN pressed=${HardwareKeyboard.instance.isControlPressed} '
      'down=${HardwareKeyboard.instance.logicalKeysPressed.map((LogicalKeyboardKey k) => k.keyLabel).toList()}');
  results.add(send(physical.usbHidUsage, logical.keyId, ui.KeyEventType.down));
  results.add(send(physical.usbHidUsage, logical.keyId, ui.KeyEventType.up));
  results.add(send(ctrlPh, ctrlLo, ui.KeyEventType.up));
  if (!results.every((sent) => sent)) _fail('Ctrl+${logical.keyLabel} 注入过程出错');
  await _frames(6);
}

Future<void> _driveWide(SettingsController settingsController) async {
  await _settle(frames: 8);
  await _forceWideLayout();
  _reportView('wide');

  // 三栏并排：树在左、列表在中
  final tree = _textElement('工作笔记本');
  final list = _textElement('周会纪要');
  if (tree == null || list == null) {
    _fail('宽屏下树或列表没渲染（tree=$tree list=$list）');
    return;
  }
  final treeX = _centerOf(tree).dx;
  final listX = _centerOf(list).dx;
  print('PANES treeX=$treeX listX=$listX');
  if (treeX >= listX) _fail('三栏顺序不对：树应在列表左侧');
  _expectText('2026 计划', '分区组节点');
  _expectText('读书笔记', '另一个笔记本下的分区');
  _expectNoText('待清理', '归档隔离');
  _expectText('未分区', '每个笔记本下的未分区行');
  await _shot('w1_three_panes');

  // 未分区行：只看该笔记本下没挂分区的笔记（分区是可选的，笔记本才是必填）
  await _tapText('未分区', '工作笔记本的未分区行');
  await _settle(frames: 4);
  _expectText('零散想法', '未分区范围');
  _expectNoText('另一页', '未分区范围排除有分区的笔记');
  _expectNoText('周会纪要', '未分区范围排除有分区的笔记');
  await _shot('w1b_unsectioned_scope');

  await _tapText('工作笔记本', '笔记本范围');
  await _settle(frames: 4);
  _expectText('周会纪要', '笔记本范围含分区与未分区的笔记');
  _expectText('零散想法', '笔记本范围含未分区笔记');
  await _shot('w1c_notebook_scope');

  // 点笔记 → 右栏编辑器 + 单标签
  await _tapText('周会纪要', '笔记条目');
  if (_tabCount() != 1) _fail('打开笔记后标签数应为 1，实际 ${_tabCount()}');
  _expectText('工作笔记本 / 周会', '面包屑');
  await _shot('w2_editor');

  // 三栏下的预览排版：整块必须贴左撑开，不能漂到中间。
  await _tapIcon(Icons.visibility_outlined, '纯预览');
  await _settle();
  _expectPreviewStretched('三栏纯预览');
  await _shot('w9_preview');
  await _tapIcon(Icons.view_column_outlined, '分栏预览');
  await _settle();
  _expectPreviewStretched('三栏分栏预览');
  await _shot('w10_split');
  await _tapIcon(Icons.edit_outlined, '回到编辑');
  await _settle();

  // 桌面快捷键：Ctrl+N 新建标签。
  // 这里刻意不先点进输入框：只点过列表条目时 primaryFocus 还在最外层
  // FocusScope，正是"刚打开软件就按 Ctrl+N"的真实场景。
  _focusDiag('after-open');
  await _pressCtrl(PhysicalKeyboardKey.keyN, LogicalKeyboardKey.keyN);
  print('CTRL+N tabs=${_tabCount()} active=${_activeTabTitle()}');
  if (_tabCount() != 2) _fail('Ctrl+N 之后应有 2 个标签，实际 ${_tabCount()}');
  await _shot('w3_ctrl_n');

  // Ctrl+Tab 切标签
  final before = _activeTabTitle();
  await _pressCtrl(PhysicalKeyboardKey.tab, LogicalKeyboardKey.tab);
  final after = _activeTabTitle();
  print('CTRL+TAB $before -> $after');
  if (before == after) _fail('Ctrl+Tab 没有切换标签（都还是 $before）');
  await _shot('w4_ctrl_tab');

  // Ctrl+W 关闭当前标签
  await _pressCtrl(PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW);
  if (_tabCount() != 1) _fail('Ctrl+W 之后应剩 1 个标签，实际 ${_tabCount()}');
  await _shot('w5_ctrl_w');

  // 树里换分区：右栏编辑器不该被关掉
  await _tapText('随想', '分区随想');
  _expectNoText('零散想法', '分区筛选');
  if (_tabCount() != 1) _fail('切分区后标签应还在，实际 ${_tabCount()}');
  await _shot('w6_section_switch');

  // 点笔记本行：中间列只看它自己分区里的笔记，行本身保持展开（#17 三栏语义）
  await _tapText('工作笔记本', '笔记本工作笔记本');
  await _settle(frames: 4);
  _dumpTexts('after-work-tap');
  _expectText('零散想法', '笔记本范围含其全部分区的笔记');
  _expectNoText('待清理', '笔记本范围排除归档笔记');
  await _shot('w7_notebook_scope');

  await _tapText('Personal', '笔记本 Personal');
  await _settle(frames: 4);
  _expectText('还没有笔记', '切到空笔记本只剩它自己的笔记');
  _expectNoText('零散想法', '别的笔记本笔记被排除');
  await _shot('w8_other_notebook');
  print('SETTINGS locale=${settingsController.settings.locale}');
}

/// 空库首启：默认笔记本自动建出来，新笔记一定带笔记本归属、分区留空。
Future<void> _driveFresh() async {
  await _settle(frames: 8);
  await _forceWideLayout();
  _reportView('fresh');

  _dumpTexts('fresh-boot');
  _expectText('我的笔记本', '首启自动创建的默认笔记本');
  _expectText('未分区', '首启笔记本下的未分区行');
  _expectNoText('快速笔记', '不再自动建默认分区');
  _expectNoText('未分组', '未分组入口已取消');
  _expectText('还没有笔记', '空列表提示');
  await _shot('f1_boot');

  // 新建笔记：草稿必须继承当前笔记本，面包屑显示「我的笔记本 / 未分区」。
  await _tapText('写笔记', '新建笔记');
  await _settle(frames: 4);
  _expectText('我的笔记本 / 未分区', '草稿继承笔记本');
  if (_tabCount() != 1) _fail('新建后应有 1 个标签，实际 ${_tabCount()}');
  await _shot('f2_draft');

  // 草稿标题留空，保存时不该落库成一条空白笔记。
  await _pressCtrl(PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW);
  await _settle(frames: 4);
  // 标签清零后 TabStrip 不再存在，_tabCount() 返回 -1，等价于 0 个标签。
  final tabs = _tabCount();
  if (tabs > 0) _fail('关闭空草稿后标签应清空，实际 $tabs');
  _expectText('还没有笔记', '空草稿不落库');
  await _shot('f3_empty_kept');
}
