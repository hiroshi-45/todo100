/// アプリの設定（オンボーディング表示済みか・リマインダー通知の有無と時刻）。
class AppSettings {
  /// 初回オンボーディングを表示済みか。
  bool onboardingSeen;

  /// 達成リマインダー（ローカル通知）を有効にしているか。
  bool remindersEnabled;

  /// リマインダーを鳴らす時刻（時 0〜23）。
  int reminderHour;

  /// リマインダーを鳴らす時刻（分 0〜59）。
  int reminderMinute;

  AppSettings({
    this.onboardingSeen = false,
    this.remindersEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  Map<String, dynamic> toJson() => {
        'onboardingSeen': onboardingSeen,
        'remindersEnabled': remindersEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        onboardingSeen: json['onboardingSeen'] as bool? ?? false,
        remindersEnabled: json['remindersEnabled'] as bool? ?? false,
        reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 20,
        reminderMinute: (json['reminderMinute'] as num?)?.toInt() ?? 0,
      );
}
