import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 達成リマインダー（毎日決まった時刻に1回鳴るローカル通知）を扱う。
///
/// 通知タップ時の遷移などは扱わず、「そっと背中を押す」だけのシンプルな実装。
/// ストア未対応・権限拒否などでも例外を投げず、静かに無効化する。
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  bool _tzReady = false;

  /// 毎日のリマインダー通知のID（固定。重複登録を避ける）。
  static const int _dailyId = 1001;

  static const String _channelId = 'daily_reminder';
  static const String _channelName = '達成リマインダー';
  static const String _channelDesc = 'やりたいことを思い出すためのやさしい通知';

  /// リマインダーで表示する文言の候補（スケジュール時に1つ選ぶ）。
  static const List<String> _messages = [
    '今日、ひとつ叶えてみない？🌱',
    'やりたいこと、進んでる？リストをのぞいてみよう✨',
    '小さな一歩でも、夢に近づく一日に🔥',
    '気になっていたこと、今日やってみよう😊',
    'あなたの「やりたい」を、未来の思い出に📸',
  ];

  /// プラグインとタイムゾーンを初期化する（多重呼び出しは無視）。
  Future<void> init() async {
    if (_ready) return;
    try {
      await _ensureTimezone();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        // 権限要求は明示的なトグル操作時に行う。
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin),
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> _ensureTimezone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      // 端末の現在UTCオフセットに一致するタイムゾーンを採用する。
      // （IANA名そのものは取得しないが、毎日のリマインダー用途では十分。）
      final offset = DateTime.now().timeZoneOffset;
      final location = _locationForOffset(offset);
      if (location != null) tz.setLocalLocation(location);
    } catch (_) {
      // 取得に失敗してもUTCで動作は継続する。
    }
    _tzReady = true;
  }

  /// 現在のUTCオフセットに一致するタイムゾーンを1つ探す。
  tz.Location? _locationForOffset(Duration offset) {
    final targetMs = offset.inMilliseconds;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.currentTimeZone.offset == targetMs) {
        // 現在時刻でのオフセットが一致するゾーンを採用。
        if (location.timeZone(now).offset == targetMs) return location;
      }
    }
    return null;
  }

  /// OSの通知許可をリクエストする。許可されたら true。
  Future<bool> requestPermission() async {
    await init();
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
            alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
      return false;
    } catch (e) {
      debugPrint('requestPermission failed: $e');
      return false;
    }
  }

  /// 毎日 [hour]:[minute] に鳴るリマインダーを（再）設定する。
  Future<void> scheduleDaily(int hour, int minute, {Random? random}) async {
    await init();
    try {
      await _plugin.cancel(_dailyId);
      final message =
          _messages[(random ?? Random()).nextInt(_messages.length)];
      await _plugin.zonedSchedule(
        _dailyId,
        'ユメツミ',
        message,
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // 毎日同時刻に繰り返す
      );
    } catch (e) {
      debugPrint('scheduleDaily failed: $e');
    }
  }

  /// リマインダーをすべて取り消す。
  Future<void> cancelDaily() async {
    await init();
    try {
      await _plugin.cancel(_dailyId);
    } catch (e) {
      debugPrint('cancelDaily failed: $e');
    }
  }

  /// 次に [hour]:[minute] を迎える日時（すでに過ぎていれば翌日）。
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
