import 'package:argonote/l10n/app_strings.dart';
import 'package:argonote/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('默认值是英文 + 默认蓝 + 跟随系统', () {
      final settings = AppSettings.defaults();

      expect(settings.language, AppLanguage.english);
      expect(settings.seedColor, AppSettings.seedColorPresets.first);
      expect(settings.themeMode, ThemeMode.system);
    });

    test('JSON 序列化可往返', () {
      const settings = AppSettings(
        languageCode: 'ja',
        seedColorValue: 0xFF0E9AA7,
        themeModeIndex: 2,
      );

      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored, settings);
      expect(restored.language, AppLanguage.japanese);
      expect(restored.themeMode, ThemeMode.dark);
    });

    test('脏数据 / 缺失字段有兜底', () {
      final restored = AppSettings.fromJson(<String, dynamic>{});

      expect(restored, AppSettings.defaults());
    });

    test('未知语言代码回退到英语', () {
      expect(AppLanguage.fromCode('xx'), AppLanguage.english);
      expect(AppLanguage.fromCode(null), AppLanguage.english);
    });

    test('copyWith 只改传入的字段', () {
      final settings = AppSettings.defaults().copyWith(themeModeIndex: 1);

      expect(settings.themeMode, ThemeMode.light);
      expect(settings.language, AppLanguage.english);
    });
  });

  group('AppLanguage', () {
    test('四种语言各有自己的 Locale', () {
      expect(AppLanguage.simplifiedChinese.locale, const Locale('zh', 'CN'));
      expect(AppLanguage.traditionalChinese.locale, const Locale('zh', 'TW'));
      expect(AppLanguage.english.locale, const Locale('en'));
      expect(AppLanguage.japanese.locale, const Locale('ja'));
    });
  });

  group('AppStrings', () {
    test('同一份 key 在四种语言下都有值', () {
      for (final language in AppLanguage.values) {
        final strings = AppStrings.forLanguage(language);
        for (final key in AppStrings.keys) {
          expect(strings.text(key), isNot(key), reason: '$language 缺少 $key');
        }
      }
    });

    test('按 Locale 取到对应语言', () {
      expect(AppStrings.forLocale(const Locale('ja')).newNote, '新規メモ');
      expect(AppStrings.forLocale(const Locale('en')).newNote, 'New note');
      expect(AppStrings.forLocale(const Locale('zh', 'TW')).newNote, '新增筆記');
      expect(AppStrings.forLocale(const Locale('zh', 'CN')).newNote, '写笔记');
    });

    test('未知语言回退到英语', () {
      expect(AppStrings.forLocale(const Locale('de')).newNote, 'New note');
    });

    test('带占位符的文案会替换标题', () {
      expect(AppStrings.forLocale(const Locale('en')).deleteMessage('Note'), 'Delete “Note”?');
    });
  });
}
