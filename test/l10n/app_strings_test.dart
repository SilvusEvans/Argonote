import 'dart:ui' show Locale;

import 'package:argonote/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('四种语言的文案表覆盖英文表全部 key，无缺漏', () {
    final keys = AppStrings.keys.toList();
    for (final language in AppLanguage.values) {
      final strings = AppStrings.forLanguage(language);
      for (final key in keys) {
        expect(strings.text(key), isNot(key), reason: '$language 缺少 $key');
      }
    }
  });

  test('带 {title} 占位符的模板各语言都保留占位符', () {
    for (final language in AppLanguage.values) {
      final strings = AppStrings.forLanguage(language);
      expect(strings.deleteMessage('X'), contains('X'));
      expect(strings.deletedMessage('Y'), contains('Y'));
    }
  });

  test('未知语言回退英文', () {
    expect(AppStrings.forLocale(const Locale('de')).save, 'Save');
  });
}
