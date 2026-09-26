import 'package:flutter/widgets.dart';

/// 应用支持的界面语言。
///
/// 只保留代码里真正需要的两件事：语言代码（用于 Locale）和展示名（用于设置页）。
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
///
/// 没有引入 flutter_gen / intl，避免额外的代码生成步骤；
/// 通过 [AppStrings.of] 从当前 [Locale] 取文案，语言切换后整棵 Widget 树自动重建。
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

  // ---- 列表页 ----
  String get newNote => text('newNote');
  String get searchHint => text('searchHint');
  String get emptyTitle => text('emptyTitle');
  String get emptySubtitle => text('emptySubtitle');
  String get noMatchTitle => text('noMatchTitle');
  String get noMatchSubtitle => text('noMatchSubtitle');
  String get deleteTitle => text('deleteTitle');
  String get filterAll => text('filterAll');
  String get folderSection => text('folderSection');
  String get tagSection => text('tagSection');
  String get folderNone => text('folderNone');
  String get tagNone => text('tagNone');

  String deleteMessage(String title) => text('deleteMessage').replaceAll('{title}', title);
  String deletedMessage(String title) => text('deletedMessage').replaceAll('{title}', title);

  // ---- 编辑页 ----
  String get createTitle => text('createTitle');
  String get editTitle => text('editTitle');
  String get titleHint => text('titleHint');
  String get contentHint => text('contentHint');
  String get editTab => text('editTab');
  String get previewTab => text('previewTab');
  String get previewEmpty => text('previewEmpty');
  String get linkCopiedHint => text('linkCopiedHint');

  // ---- 标签 / 文件夹 ----
  String get tagsLabel => text('tagsLabel');
  String get addTag => text('addTag');
  String get tagNameHint => text('tagNameHint');
  String get removeTag => text('removeTag');
  String get folderLabel => text('folderLabel');
  String get newFolder => text('newFolder');
  String get folderNameHint => text('folderNameHint');
  String get deleteFolderTitle => text('deleteFolderTitle');
  String get deleteFolderMessage => text('deleteFolderMessage');
  String get folderCreatedMessage => text('folderCreatedMessage');

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
    'newNote': '写笔记',
    'searchHint': '搜索标题或内容',
    'emptyTitle': '还没有笔记',
    'emptySubtitle': '点击右下角「写笔记」开始第一条',
    'noMatchTitle': '没有匹配的笔记',
    'noMatchSubtitle': '换个关键词试试',
    'deleteTitle': '删除笔记',
    'deleteMessage': '确定删除「{title}」吗？',
    'deletedMessage': '已删除「{title}」',
    'filterAll': '全部',
    'folderSection': '文件夹',
    'tagSection': '标签',
    'folderNone': '未归类',
    'tagNone': '无标签',
    'createTitle': '新建笔记',
    'editTitle': '编辑笔记',
    'titleHint': '标题',
    'contentHint': '写点什么…（支持 Markdown）',
    'editTab': '编辑',
    'previewTab': '预览',
    'previewEmpty': '还没有内容可预览',
    'linkCopiedHint': '链接：',
    'tagsLabel': '标签',
    'addTag': '添加标签',
    'tagNameHint': '标签名称',
    'removeTag': '移除标签',
    'folderLabel': '文件夹',
    'newFolder': '新建文件夹',
    'folderNameHint': '文件夹名称',
    'deleteFolderTitle': '删除文件夹',
    'deleteFolderMessage': '删除后，该文件夹下的笔记会变为「未归类」，笔记本身不会丢失。',
    'folderCreatedMessage': '已创建文件夹',
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
    'newNote': 'New note',
    'searchHint': 'Search title or content',
    'emptyTitle': 'No notes yet',
    'emptySubtitle': 'Tap “New note” to write your first one',
    'noMatchTitle': 'No matching notes',
    'noMatchSubtitle': 'Try a different keyword',
    'deleteTitle': 'Delete note',
    'deleteMessage': 'Delete “{title}”?',
    'deletedMessage': 'Deleted “{title}”',
    'filterAll': 'All',
    'folderSection': 'Folders',
    'tagSection': 'Tags',
    'folderNone': 'Unfiled',
    'tagNone': 'Untagged',
    'createTitle': 'New note',
    'editTitle': 'Edit note',
    'titleHint': 'Title',
    'contentHint': 'Write something… (Markdown supported)',
    'editTab': 'Edit',
    'previewTab': 'Preview',
    'previewEmpty': 'Nothing to preview yet',
    'linkCopiedHint': 'Link: ',
    'tagsLabel': 'Tags',
    'addTag': 'Add tag',
    'tagNameHint': 'Tag name',
    'removeTag': 'Remove tag',
    'folderLabel': 'Folder',
    'newFolder': 'New folder',
    'folderNameHint': 'Folder name',
    'deleteFolderTitle': 'Delete folder',
    'deleteFolderMessage': 'Notes inside will become “Unfiled”. Notes themselves are kept.',
    'folderCreatedMessage': 'Folder created',
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
    'newNote': '新規メモ',
    'searchHint': 'タイトルまたは本文を検索',
    'emptyTitle': 'メモがありません',
    'emptySubtitle': '右下の「新規メモ」から始めましょう',
    'noMatchTitle': '一致するメモがありません',
    'noMatchSubtitle': '別のキーワードで試してください',
    'deleteTitle': 'メモを削除',
    'deleteMessage': '「{title}」を削除しますか？',
    'deletedMessage': '「{title}」を削除しました',
    'filterAll': 'すべて',
    'folderSection': 'フォルダ',
    'tagSection': 'タグ',
    'folderNone': '未分類',
    'tagNone': 'タグなし',
    'createTitle': '新規メモ',
    'editTitle': 'メモを編集',
    'titleHint': 'タイトル',
    'contentHint': '何か書いてみましょう…（Markdown 対応）',
    'editTab': '編集',
    'previewTab': 'プレビュー',
    'previewEmpty': 'プレビューする内容がありません',
    'linkCopiedHint': 'リンク：',
    'tagsLabel': 'タグ',
    'addTag': 'タグを追加',
    'tagNameHint': 'タグ名',
    'removeTag': 'タグを削除',
    'folderLabel': 'フォルダ',
    'newFolder': 'フォルダを作成',
    'folderNameHint': 'フォルダ名',
    'deleteFolderTitle': 'フォルダを削除',
    'deleteFolderMessage': 'フォルダ内のメモは「未分類」になります。メモ自体は削除されません。',
    'folderCreatedMessage': 'フォルダを作成しました',
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
    'newNote': '新增筆記',
    'searchHint': '搜尋標題或內容',
    'emptyTitle': '還沒有筆記',
    'emptySubtitle': '點右下角「新增筆記」開始第一則',
    'noMatchTitle': '沒有符合的筆記',
    'noMatchSubtitle': '換個關鍵字試試',
    'deleteTitle': '刪除筆記',
    'deleteMessage': '確定刪除「{title}」嗎？',
    'deletedMessage': '已刪除「{title}」',
    'filterAll': '全部',
    'folderSection': '資料夾',
    'tagSection': '標籤',
    'folderNone': '未分類',
    'tagNone': '無標籤',
    'createTitle': '新增筆記',
    'editTitle': '編輯筆記',
    'titleHint': '標題',
    'contentHint': '寫點什麼…（支援 Markdown）',
    'editTab': '編輯',
    'previewTab': '預覽',
    'previewEmpty': '還沒有可預覽的內容',
    'linkCopiedHint': '連結：',
    'tagsLabel': '標籤',
    'addTag': '新增標籤',
    'tagNameHint': '標籤名稱',
    'removeTag': '移除標籤',
    'folderLabel': '資料夾',
    'newFolder': '新增資料夾',
    'folderNameHint': '資料夾名稱',
    'deleteFolderTitle': '刪除資料夾',
    'deleteFolderMessage': '刪除後，資料夾內的筆記會變成「未分類」，筆記本身不會遺失。',
    'folderCreatedMessage': '已建立資料夾',
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
