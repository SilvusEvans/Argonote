import 'package:flutter/widgets.dart';

/// 应用支持的界面语言。
enum AppLanguage {
  simplifiedChinese('zh_CN', '简体中文'),
  english('en', 'English'),
  japanese('ja', '日本語'),
  traditionalChinese('zh_TW', '繁體中文');

  const AppLanguage(this.code, this.label);

  /// 持久化用的稳定标识（不随语言切换而变化）。
  final String code;

  /// 设置页里用各自语言展示的名字。
  final String label;

  static AppLanguage fromCode(String? code) {
    for (final language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return AppLanguage.english;
  }

  Locale get locale {
    switch (this) {
      case AppLanguage.simplifiedChinese:
        return const Locale('zh', 'CN');
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.japanese:
        return const Locale('ja');
      case AppLanguage.traditionalChinese:
        return const Locale('zh', 'TW');
    }
  }
}

/// 极简多语言方案：一张 key → 文案 的表 + 一组类型安全的 getter。
class AppStrings {
  const AppStrings._(Map<String, String> values) : _values = values;

  final Map<String, String> _values;

  static const Map<String, Map<String, String>> _bundles = {
    'zh_CN': _zhCn,
    'en': _en,
    'ja': _ja,
    'zh_TW': _zhTw,
  };

  static AppStrings of(BuildContext context) => forLocale(Localizations.localeOf(context));

  static AppStrings forLocale(Locale locale) {
    final code = _codeOf(locale);
    return AppStrings._(_bundles[code] ?? _en);
  }

  static AppStrings forLanguage(AppLanguage language) =>
      AppStrings._(_bundles[language.code] ?? _en);

  static String _codeOf(Locale locale) {
    if (locale.languageCode == 'zh') {
      return locale.countryCode == 'TW' ? 'zh_TW' : 'zh_CN';
    }
    return locale.languageCode; // en / ja / 其它一律回退到 en
  }

  /// 直接按 key 取文案；缺失时回退到英文，再缺失就返回 key 本身。
  String text(String key) => _values[key] ?? _en[key] ?? key;

  /// 全部文案 key（以英文表为准），便于测试校验各语言是否齐全。
  static Iterable<String> get keys => _en.keys;

  // ---- 通用 ----
  String get appTitle => text('appTitle');
  String get save => text('save');
  String get cancel => text('cancel');
  String get delete => text('delete');
  String get confirm => text('confirm');
  String get undo => text('undo');
  String get settings => text('settings');
  String get rename => text('rename');
  String get close => text('close');
  String get untitled => text('untitled');

  // ---- 列表页 ----
  String get newNote => text('newNote');
  String get searchHint => text('searchHint');
  String get emptyTitle => text('emptyTitle');
  String get emptySubtitle => text('emptySubtitle');
  String get noMatchTitle => text('noMatchTitle');
  String get noMatchSubtitle => text('noMatchSubtitle');
  String get deleteTitle => text('deleteTitle');
  String get tagSection => text('tagSection');
  String get tagNone => text('tagNone');
  String get sortBy => text('sortBy');
  String get sortUpdated => text('sortUpdated');
  String get sortCreated => text('sortCreated');
  String get sortTitle => text('sortTitle');

  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
  String archivedMessage(String title) => text('archivedMessage').replaceAll('{title}', title);

  // ---- 笔记树（OneNote 体系） ----
  String get allNotes => text('allNotes');
  String get pinnedScope => text('pinnedScope');
  String get archived => text('archived');
  String get archive => text('archive');
  String get unarchive => text('unarchive');
  String get defaultNotebook => text('defaultNotebook');
  String get unsectioned => text('unsectioned');
  String get notebookLabel => text('notebookLabel');
  String get sectionLabel => text('sectionLabel');
  String get groupLabel => text('groupLabel');
  String get newNotebook => text('newNotebook');
  String get notebookNameHint => text('notebookNameHint');
  String get newSection => text('newSection');
  String get sectionNameHint => text('sectionNameHint');
  String get newSectionGroup => text('newSectionGroup');
  String get groupNameHint => text('groupNameHint');
  String get deleteNotebookTitle => text('deleteNotebookTitle');
  String get deleteNotebookMessage => text('deleteNotebookMessage');
  String get deleteSectionTitle => text('deleteSectionTitle');
  String get deleteSectionMessage => text('deleteSectionMessage');
  String get deleteGroupTitle => text('deleteGroupTitle');
  String get deleteGroupMessage => text('deleteGroupMessage');

  // ---- 归档 / 置顶 ----
  String get pin => text('pin');
  String get unpin => text('unpin');
  String get restore => text('restore');
  String get deleteForever => text('deleteForever');
  String get emptyArchive => text('emptyArchive');
  String get emptyArchiveConfirm => text('emptyArchiveConfirm');
  String get archiveEmpty => text('archiveEmpty');

  // ---- 标签页 ----
  String get tabCloseOthers => text('tabCloseOthers');
  String get tabCloseAll => text('tabCloseAll');
  String get saved => text('saved');

  // ---- 编辑页 ----
  String get createTitle => text('createTitle');
  String get editTitle => text('editTitle');
  String get titleHint => text('titleHint');
  String get contentHint => text('contentHint');
  String get editTab => text('editTab');
  String get previewTab => text('previewTab');
  String get splitTab => text('splitTab');
  String get previewEmpty => text('previewEmpty');
  String get linkCopiedHint => text('linkCopiedHint');
  String get wikiLinkNotFound => text('wikiLinkNotFound');
  String get copyMarkdown => text('copyMarkdown');
  String get copiedToClipboard => text('copiedToClipboard');
  String get statsChars => text('statsChars');
  String get statsWords => text('statsWords');
  String get statsLines => text('statsLines');

  // ---- 工具栏 ----
  String get tbBold => text('tbBold');
  String get tbItalic => text('tbItalic');
  String get tbHeading => text('tbHeading');
  String get tbList => text('tbList');
  String get tbChecklist => text('tbChecklist');
  String get tbCode => text('tbCode');
  String get tbQuote => text('tbQuote');
  String get tbLink => text('tbLink');
  String get tbTable => text('tbTable');
  String get tbDivider => text('tbDivider');

  // ---- 标签 / 分区归属 ----
  String get tagsLabel => text('tagsLabel');
  String get addTag => text('addTag');
  String get tagNameHint => text('tagNameHint');
  String get removeTag => text('removeTag');
  String get sectionOfNote => text('sectionOfNote');

  // ---- 设置页 ----
  String get settingsTitle => text('settingsTitle');
  String get languageSection => text('languageSection');
  String get languageSubtitle => text('languageSubtitle');
  String get themeColorSection => text('themeColorSection');
  String get themeColorSubtitle => text('themeColorSubtitle');
  String get themeModeSection => text('themeModeSection');
  String get themeModeSystem => text('themeModeSystem');
  String get themeModeLight => text('themeModeLight');
  String get themeModeDark => text('themeModeDark');
  String get restoreDefaults => text('restoreDefaults');
  String get settingsApplied => text('settingsApplied');

  static const Map<String, String> _zhCn = {
    'appTitle': 'Argonote',
    'save': '保存',
    'cancel': '取消',
    'delete': '删除',
    'confirm': '确定',
    'undo': '撤销',
    'settings': '设置',
    'rename': '重命名',
    'close': '关闭',
    'untitled': '无标题',
    'newNote': '写笔记',
    'searchHint': '搜索标题或内容',
    'emptyTitle': '还没有笔记',
    'emptySubtitle': '点上方「写笔记」开始第一条',
    'noMatchTitle': '没有匹配的笔记',
    'noMatchSubtitle': '换个关键词试试',
    'deleteTitle': '删除笔记',
    'deleteMessage': '确定删除「{title}」吗？',
    'archivedMessage': '已归档「{title}」',
    'tagSection': '标签',
    'tagNone': '无标签',
    'sortBy': '排序',
    'sortUpdated': '最近修改',
    'sortCreated': '最近创建',
    'sortTitle': '标题',
    'allNotes': '所有笔记',
    'pinnedScope': '置顶',
    'archived': '已归档',
    'defaultNotebook': '我的笔记本',
    'unsectioned': '未分区',
    'notebookLabel': '笔记本',
    'sectionLabel': '分区',
    'groupLabel': '分区组',
    'newNotebook': '新建笔记本',
    'notebookNameHint': '笔记本名称',
    'newSection': '新建分区',
    'sectionNameHint': '分区名称',
    'newSectionGroup': '新建分区组',
    'groupNameHint': '分区组名称',
    'deleteNotebookTitle': '删除笔记本',
    'deleteNotebookMessage': '删除后，其中的分区和分区组会一并删除，笔记移入其他笔记本的「未分区」。笔记本身不会丢失。',
    'deleteSectionTitle': '删除分区',
    'deleteSectionMessage': '删除后，该分区下的笔记会留在笔记本的「未分区」里，笔记本身不会丢失。',
    'deleteGroupTitle': '删除分区组',
    'deleteGroupMessage': '组内的分区会提升到笔记本下，不会被删除。',
    'pin': '置顶',
    'unpin': '取消置顶',
    'restore': '还原',
    'archive': '归档',
    'unarchive': '取消归档',
    'deleteForever': '彻底删除',
    'emptyArchive': '清空归档',
    'emptyArchiveConfirm': '归档里的笔记将被永久删除，无法恢复。确定继续吗？',
    'archiveEmpty': '归档是空的',
    'tabCloseOthers': '关闭其它标签',
    'tabCloseAll': '关闭全部标签',
    'saved': '已保存',
    'createTitle': '新建笔记',
    'editTitle': '编辑笔记',
    'titleHint': '标题',
    'contentHint': '写点什么…（支持 Markdown 与 [[双链]]）',
    'editTab': '编辑',
    'previewTab': '预览',
    'splitTab': '分栏',
    'previewEmpty': '还没有内容可预览',
    'linkCopiedHint': '链接：',
    'wikiLinkNotFound': '没有找到同名笔记',
    'copyMarkdown': '复制为 Markdown',
    'copiedToClipboard': '已复制到剪贴板',
    'statsChars': '字符',
    'statsWords': '字数',
    'statsLines': '行数',
    'tbBold': '加粗',
    'tbItalic': '斜体',
    'tbHeading': '标题',
    'tbList': '列表',
    'tbChecklist': '任务列表',
    'tbCode': '代码',
    'tbQuote': '引用',
    'tbLink': '链接',
    'tbTable': '表格',
    'tbDivider': '分割线',
    'tagsLabel': '标签',
    'addTag': '添加标签',
    'tagNameHint': '标签名称',
    'removeTag': '移除标签',
    'sectionOfNote': '分区',
    'settingsTitle': '设置',
    'languageSection': '界面语言',
    'languageSubtitle': '切换后立即生效，并会记住你的选择',
    'themeColorSection': '主题配色',
    'themeColorSubtitle': '选择应用的主色调',
    'themeModeSection': '外观',
    'themeModeSystem': '跟随系统',
    'themeModeLight': '浅色',
    'themeModeDark': '深色',
    'restoreDefaults': '恢复默认设置',
    'settingsApplied': '设置已保存并生效',
  };

  static const Map<String, String> _en = {
    'appTitle': 'Argonote',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'confirm': 'OK',
    'undo': 'Undo',
    'settings': 'Settings',
    'rename': 'Rename',
    'close': 'Close',
    'untitled': 'Untitled',
    'newNote': 'New note',
    'searchHint': 'Search title or content',
    'emptyTitle': 'No notes yet',
    'emptySubtitle': 'Tap “New note” above to write your first one',
    'noMatchTitle': 'No matching notes',
    'noMatchSubtitle': 'Try a different keyword',
    'deleteTitle': 'Delete note',
    'deleteMessage': 'Delete “{title}”?',
    'archivedMessage': 'Archived “{title}”',
    'tagSection': 'Tags',
    'tagNone': 'Untagged',
    'sortBy': 'Sort',
    'sortUpdated': 'Recently edited',
    'sortCreated': 'Recently created',
    'sortTitle': 'Title',
    'allNotes': 'All notes',
    'pinnedScope': 'Pinned',
    'archived': 'Archived',
    'defaultNotebook': 'My Notebook',
    'unsectioned': 'Unsectioned',
    'notebookLabel': 'Notebook',
    'sectionLabel': 'Section',
    'groupLabel': 'Section group',
    'newNotebook': 'New notebook',
    'notebookNameHint': 'Notebook name',
    'newSection': 'New section',
    'sectionNameHint': 'Section name',
    'newSectionGroup': 'New section group',
    'groupNameHint': 'Section group name',
    'deleteNotebookTitle': 'Delete notebook',
    'deleteNotebookMessage': 'Its sections and groups will be removed; notes move to “Unsectioned” in another notebook. Notes are kept.',
    'deleteSectionTitle': 'Delete section',
    'deleteSectionMessage': 'Notes inside stay in the notebook under “Unsectioned”. Notes themselves are kept.',
    'deleteGroupTitle': 'Delete section group',
    'deleteGroupMessage': 'Sections inside move up to the notebook. They are not deleted.',
    'pin': 'Pin',
    'unpin': 'Unpin',
    'restore': 'Restore',
    'archive': 'Archive',
    'unarchive': 'Unarchive',
    'deleteForever': 'Delete forever',
    'emptyArchive': 'Empty archive',
    'emptyArchiveConfirm': 'Archived notes will be permanently removed. Continue?',
    'archiveEmpty': 'Archive is empty',
    'tabCloseOthers': 'Close other tabs',
    'tabCloseAll': 'Close all tabs',
    'saved': 'Saved',
    'createTitle': 'New note',
    'editTitle': 'Edit note',
    'titleHint': 'Title',
    'contentHint': 'Write something… (Markdown & [[wiki links]] supported)',
    'editTab': 'Edit',
    'previewTab': 'Preview',
    'splitTab': 'Split',
    'previewEmpty': 'Nothing to preview yet',
    'linkCopiedHint': 'Link: ',
    'wikiLinkNotFound': 'No note with that title',
    'copyMarkdown': 'Copy as Markdown',
    'copiedToClipboard': 'Copied to clipboard',
    'statsChars': 'chars',
    'statsWords': 'words',
    'statsLines': 'lines',
    'tbBold': 'Bold',
    'tbItalic': 'Italic',
    'tbHeading': 'Heading',
    'tbList': 'List',
    'tbChecklist': 'Task list',
    'tbCode': 'Code',
    'tbQuote': 'Quote',
    'tbLink': 'Link',
    'tbTable': 'Table',
    'tbDivider': 'Divider',
    'tagsLabel': 'Tags',
    'addTag': 'Add tag',
    'tagNameHint': 'Tag name',
    'removeTag': 'Remove tag',
    'sectionOfNote': 'Section',
    'settingsTitle': 'Settings',
    'languageSection': 'Language',
    'languageSubtitle': 'Applies instantly and is remembered',
    'themeColorSection': 'Theme colour',
    'themeColorSubtitle': 'Pick the primary colour of the app',
    'themeModeSection': 'Appearance',
    'themeModeSystem': 'System',
    'themeModeLight': 'Light',
    'themeModeDark': 'Dark',
    'restoreDefaults': 'Restore defaults',
    'settingsApplied': 'Settings saved and applied',
  };

  static const Map<String, String> _ja = {
    'appTitle': 'Argonote',
    'save': '保存',
    'cancel': 'キャンセル',
    'delete': '削除',
    'confirm': 'OK',
    'undo': '元に戻す',
    'settings': '設定',
    'rename': '名前を変更',
    'close': '閉じる',
    'untitled': '無題',
    'newNote': '新規メモ',
    'searchHint': 'タイトルまたは本文を検索',
    'emptyTitle': 'メモがありません',
    'emptySubtitle': '上の「新規メモ」から始めましょう',
    'noMatchTitle': '一致するメモがありません',
    'noMatchSubtitle': '別のキーワードで試してください',
    'deleteTitle': 'メモを削除',
    'deleteMessage': '「{title}」を削除しますか？',
    'archivedMessage': '「{title}」をアーカイブしました',
    'tagSection': 'タグ',
    'tagNone': 'タグなし',
    'sortBy': '並び替え',
    'sortUpdated': '更新順',
    'sortCreated': '作成順',
    'sortTitle': 'タイトル',
    'allNotes': 'すべてのメモ',
    'pinnedScope': 'ピン留め',
    'archived': 'アーカイブ',
    'defaultNotebook': 'マイノートブック',
    'unsectioned': '未セクション',
    'notebookLabel': 'ノートブック',
    'sectionLabel': 'セクション',
    'groupLabel': 'セクショングループ',
    'newNotebook': '新しいノートブック',
    'notebookNameHint': 'ノートブック名',
    'newSection': '新しいセクション',
    'sectionNameHint': 'セクション名',
    'newSectionGroup': '新しいセクショングループ',
    'groupNameHint': 'セクショングループ名',
    'deleteNotebookTitle': 'ノートブックを削除',
    'deleteNotebookMessage': '内のセクションとグループも削除され、メモは他のノートブックの「未セクション」に移動します。メモ自体は残ります。',
    'deleteSectionTitle': 'セクションを削除',
    'deleteSectionMessage': 'セクション内のメモはノートブックの「未セクション」に残ります。メモ自体は削除されません。',
    'deleteGroupTitle': 'セクショングループを削除',
    'deleteGroupMessage': 'グループ内のセクションはノートブック直下に移動します。削除されません。',
    'pin': 'ピン留め',
    'unpin': 'ピン留めを解除',
    'restore': '復元',
    'archive': 'アーカイブ',
    'unarchive': 'アーカイブ解除',
    'deleteForever': '完全に削除',
    'emptyArchive': 'アーカイブを空にする',
    'emptyArchiveConfirm': 'アーカイブしたメモは復元できません。続行しますか？',
    'archiveEmpty': 'アーカイブは空です',
    'tabCloseOthers': '他のタブを閉じる',
    'tabCloseAll': 'すべてのタブを閉じる',
    'saved': '保存しました',
    'createTitle': '新規メモ',
    'editTitle': 'メモを編集',
    'titleHint': 'タイトル',
    'contentHint': '何か書いてみましょう…（Markdown と [[Wリンク]] 対応）',
    'editTab': '編集',
    'previewTab': 'プレビュー',
    'splitTab': '分割',
    'previewEmpty': 'プレビューする内容がありません',
    'linkCopiedHint': 'リンク：',
    'wikiLinkNotFound': '同じタイトルのメモが見つかりません',
    'copyMarkdown': 'Markdown としてコピー',
    'copiedToClipboard': 'クリップボードにコピーしました',
    'statsChars': '文字',
    'statsWords': '語',
    'statsLines': '行',
    'tbBold': '太字',
    'tbItalic': '斜体',
    'tbHeading': '見出し',
    'tbList': '列表',
    'tbChecklist': 'タスクリスト',
    'tbCode': 'コード',
    'tbQuote': '引用',
    'tbLink': 'リンク',
    'tbTable': '表',
    'tbDivider': '区切り線',
    'tagsLabel': 'タグ',
    'addTag': 'タグを追加',
    'tagNameHint': 'タグ名',
    'removeTag': 'タグを削除',
    'sectionOfNote': 'セクション',
    'settingsTitle': '設定',
    'languageSection': '表示言語',
    'languageSubtitle': 'すぐに反映され、選択は保存されます',
    'themeColorSection': 'テーマカラー',
    'themeColorSubtitle': 'アプリのメインカラーを選択',
    'themeModeSection': '外観',
    'themeModeSystem': 'システム',
    'themeModeLight': 'ライト',
    'themeModeDark': 'ダーク',
    'restoreDefaults': '既定値に戻す',
    'settingsApplied': '設定を保存して反映しました',
  };

  static const Map<String, String> _zhTw = {
    'appTitle': 'Argonote',
    'save': '儲存',
    'cancel': '取消',
    'delete': '刪除',
    'confirm': '確定',
    'undo': '復原',
    'settings': '設定',
    'rename': '重新命名',
    'close': '關閉',
    'untitled': '無標題',
    'newNote': '新增筆記',
    'searchHint': '搜尋標題或內容',
    'emptyTitle': '還沒有筆記',
    'emptySubtitle': '點上方「新增筆記」開始第一則',
    'noMatchTitle': '沒有符合的筆記',
    'noMatchSubtitle': '換個關鍵字試試',
    'deleteTitle': '刪除筆記',
    'deleteMessage': '確定刪除「{title}」嗎？',
    'archivedMessage': '已封存「{title}」',
    'tagSection': '標籤',
    'tagNone': '無標籤',
    'sortBy': '排序',
    'sortUpdated': '最近編輯',
    'sortCreated': '最近建立',
    'sortTitle': '標題',
    'allNotes': '所有筆記',
    'pinnedScope': '置頂',
    'archived': '已封存',
    'defaultNotebook': '我的筆記本',
    'unsectioned': '未分區',
    'notebookLabel': '筆記本',
    'sectionLabel': '區段',
    'groupLabel': '區段群組',
    'newNotebook': '新增筆記本',
    'notebookNameHint': '筆記本名稱',
    'newSection': '新增區段',
    'sectionNameHint': '區段名稱',
    'newSectionGroup': '新增區段群組',
    'groupNameHint': '區段群組名稱',
    'deleteNotebookTitle': '刪除筆記本',
    'deleteNotebookMessage': '刪除後，其中的區段與區段群組一併刪除，筆記移入其他筆記本的「未分區」。筆記本身不會遺失。',
    'deleteSectionTitle': '刪除區段',
    'deleteSectionMessage': '刪除後，區段內的筆記會留在筆記本的「未分區」裡，筆記本身不會遺失。',
    'deleteGroupTitle': '刪除區段群組',
    'deleteGroupMessage': '群組內的區段會提升到筆記本下，不會被刪除。',
    'pin': '置頂',
    'unpin': '取消置頂',
    'restore': '還原',
    'archive': '封存',
    'unarchive': '取消封存',
    'deleteForever': '彻底刪除',
    'emptyArchive': '清空封存',
    'emptyArchiveConfirm': '封存內的筆記將永久刪除且無法復原。確定繼續嗎？',
    'archiveEmpty': '封存是空的',
    'tabCloseOthers': '關閉其他索引標籤',
    'tabCloseAll': '關閉所有索引標籤',
    'saved': '已儲存',
    'createTitle': '新增筆記',
    'editTitle': '編輯筆記',
    'titleHint': '標題',
    'contentHint': '寫點什麼…（支援 Markdown 與 [[雙鏈]]）',
    'editTab': '編輯',
    'previewTab': '預覽',
    'splitTab': '分欄',
    'previewEmpty': '還沒有可預覽的內容',
    'linkCopiedHint': '連結：',
    'wikiLinkNotFound': '找不到同標題的筆記',
    'copyMarkdown': '複製為 Markdown',
    'copiedToClipboard': '已複製到剪貼簿',
    'statsChars': '字元',
    'statsWords': '字數',
    'statsLines': '行數',
    'tbBold': '粗體',
    'tbItalic': '斜體',
    'tbHeading': '標題',
    'tbList': '清單',
    'tbChecklist': '待辦清單',
    'tbCode': '程式碼',
    'tbQuote': '引用',
    'tbLink': '連結',
    'tbTable': '表格',
    'tbDivider': '分隔線',
    'tagsLabel': '標籤',
    'addTag': '新增標籤',
    'tagNameHint': '標籤名稱',
    'removeTag': '移除標籤',
    'sectionOfNote': '區段',
    'settingsTitle': '設定',
    'languageSection': '介面語言',
    'languageSubtitle': '立即生效，並記住你的選擇',
    'themeColorSection': '主題配色',
    'themeColorSubtitle': '選擇應用程式的主色調',
    'themeModeSection': '外觀',
    'themeModeSystem': '跟隨系統',
    'themeModeLight': '淺色',
    'themeModeDark': '深色',
    'restoreDefaults': '恢復預設設定',
    'settingsApplied': '設定已儲存並生效',
  };
}
