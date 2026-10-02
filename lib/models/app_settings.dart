import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// 应用级设置：界面语言 + 主题配色 + 深浅模式。
///
/// 全部字段都可 JSON 序列化，落盘后下次启动自动恢复。
class AppSettings {
  const AppSettings({
    required this.languageCode,
    required this.seedColorValue,
    required this.themeModeIndex,
  });

  /// [AppLanguage.code]，持久化只存代码，不存 Locale 对象。
  final String languageCode;

  /// 主题种子色的 ARGB 整数值。
  final int seedColorValue;

  /// 0 = 跟随系统，1 = 浅色，2 = 深色。
  final int themeModeIndex;

  static AppSettings defaults() => AppSettings(
        languageCode: AppLanguage.english.code,
        seedColorValue: AppSettings.seedColorPresets.first.toARGB32(),
        themeModeIndex: 0,
      );

  /// 设置页里可选的几组主色，第一项是默认值。
  static const List<Color> seedColorPresets = <Color>[
    Color(0xFF4F7CFF), // 默认蓝
    Color(0xFF2E9E6B), // 绿
    Color(0xFFF2792B), // 橙
    Color(0xFF7A5CFF), // 紫
    Color(0xFFE2567C), // 玫红
    Color(0xFF0E9AA7), // 青
  ];

  AppLanguage get language => AppLanguage.fromCode(languageCode);

  Locale get locale => language.locale;

  Color get seedColor => Color(seedColorValue);

  ThemeMode get themeMode => switch (themeModeIndex) {
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  AppSettings copyWith({
    String? languageCode,
    int? seedColorValue,
    int? themeModeIndex,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      seedColorValue: seedColorValue ?? this.seedColorValue,
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'languageCode': languageCode,
        'seedColorValue': seedColorValue,
        'themeModeIndex': themeModeIndex,
      };

  /// 反序列化时对缺失字段做兜底，单个字段坏掉不至于整份设置失效。
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      languageCode: (json['languageCode'] as String?) ?? defaults.languageCode,
      seedColorValue: (json['seedColorValue'] as int?) ?? defaults.seedColorValue,
      themeModeIndex: (json['themeModeIndex'] as int?) ?? defaults.themeModeIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.languageCode == languageCode &&
          other.seedColorValue == seedColorValue &&
          other.themeModeIndex == themeModeIndex;

  @override
  int get hashCode => Object.hash(languageCode, seedColorValue, themeModeIndex);
}
