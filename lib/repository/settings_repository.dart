import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// アプリ設定（オンボーディング・リマインダー通知）の状態を管理する。
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._storage, this._notifications);

  final StorageService _storage;
  final NotificationService _notifications;

  AppSettings _settings = AppSettings();
  bool _loaded = false;

  bool get loaded => _loaded;
  bool get onboardingSeen => _settings.onboardingSeen;
  bool get remindersEnabled => _settings.remindersEnabled;
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _settings.reminderHour, minute: _settings.reminderMinute);

  Future<void> init() async {
    _settings = await _storage.loadSettings();
    _loaded = true;
    notifyListeners();
    // 通知ONなら、起動時にスケジュールを貼り直す（OS再起動・端末更新の保険）。
    if (_settings.remindersEnabled) {
      await _notifications.scheduleDaily(
          _settings.reminderHour, _settings.reminderMinute);
    }
  }

  Future<void> markOnboardingSeen() async {
    if (_settings.onboardingSeen) return;
    _settings.onboardingSeen = true;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  /// リマインダーのON/OFFを切り替える。ONにする際は権限を要求し、
  /// 拒否された場合は false を返してOFFのままにする。
  Future<bool> setRemindersEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _notifications.requestPermission();
      if (!granted) {
        notifyListeners(); // スイッチを元に戻すため再描画
        return false;
      }
      await _notifications.scheduleDaily(
          _settings.reminderHour, _settings.reminderMinute);
    } else {
      await _notifications.cancelDaily();
    }
    _settings.remindersEnabled = enabled;
    notifyListeners();
    await _storage.saveSettings(_settings);
    return true;
  }

  /// リマインダー時刻を変更する。ON のときは即座に再スケジュール。
  Future<void> setReminderTime(TimeOfDay time) async {
    _settings.reminderHour = time.hour;
    _settings.reminderMinute = time.minute;
    if (_settings.remindersEnabled) {
      await _notifications.scheduleDaily(time.hour, time.minute);
    }
    notifyListeners();
    await _storage.saveSettings(_settings);
  }
}
