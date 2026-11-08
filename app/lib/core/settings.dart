import 'package:flutter/material.dart';

/// 用户偏好（存 SharedPreferences，不进 SQLite——它不是账本数据）
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.reminderEnabled = false,
    this.reminderDay = 5,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  final ThemeMode themeMode;

  /// 月度提醒：每月几号提醒存钱
  final bool reminderEnabled;
  final int reminderDay;
  final int reminderHour;
  final int reminderMinute;

  static const defaults = AppSettings();

  String get reminderLabel =>
      '每月 ${reminderDay.toString().padLeft(2, '0')} 日 '
      '${reminderHour.toString().padLeft(2, '0')}:'
      '${reminderMinute.toString().padLeft(2, '0')}';

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? reminderEnabled,
    int? reminderDay,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderDay: reminderDay ?? this.reminderDay,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );

  static ThemeMode parseThemeMode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
        ThemeMode.system => '跟随系统',
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
      };
}
