import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/settings.dart';

/// 月度提醒：每月固定某天某点提醒「该存钱了」。
///
/// 用 inexact 模式排程，不申请 SCHEDULE_EXACT_ALARM —— 提醒差几分钟无所谓，
/// 但省掉一个用户要手动去系统设置里开的权限。
class ReminderService {
  ReminderService();

  static const _channelId = 'monthly_saving_reminder';
  static const _notificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('timezone fallback: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// 单条目标提醒用的 id 区间：2000 + 序号（每次 sync 全量重排，序号可复用）
  static const _goalIdBase = 2000;
  static const _goalIdMax = 40;

  Future<bool> notificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  /// 按设置重排提醒；body 用来放当前欠缴金额之类的实时信息
  Future<void> sync(AppSettings settings, {String? body}) async {
    await init();
    await _plugin.cancel(id: _notificationId);
    if (!settings.reminderEnabled) return;

    final next = _nextInstance(settings.reminderDay, settings.reminderHour,
        settings.reminderMinute);
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: '该存钱了',
      body: body ?? '打开一个小目标，看看这个月还差多少',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '月度存钱提醒',
          channelDescription: '每月提醒一次，告诉你本月还差多少',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// 按每个目标自己的「每月几号存」排提醒。
  /// [items] 是 (标题后缀, 第几号, 本条要存多少钱文案) —— 由调用方从引擎算好。
  Future<void> syncGoalReminders(List<GoalReminder> items, AppSettings settings) async {
    await init();
    for (var i = 0; i < _goalIdMax; i++) {
      await _plugin.cancel(id: _goalIdBase + i);
    }
    if (!settings.reminderEnabled) return;

    final shown = items.where((e) => e.payDay >= 1 && e.payDay <= 28).take(_goalIdMax);
    var idx = 0;
    for (final it in shown) {
      await _plugin.zonedSchedule(
        id: _goalIdBase + idx,
        title: '${it.name}：该存钱了',
        body: it.body,
        scheduledDate: _nextInstance(
            it.payDay, settings.reminderHour, settings.reminderMinute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            '月度存钱提醒',
            channelDescription: '每月提醒一次，告诉你本月还差多少',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
      idx++;
    }
  }

  Future<void> cancel() async {
    await init();
    await _plugin.cancel(id: _notificationId);
  }

  Future<void> showNow({String? body}) async {
    await init();
    await _plugin.show(
      id: _notificationId + 1,
      title: '该存钱了',
      body: body ?? '这是提醒效果预览',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '月度存钱提醒',
          channelDescription: '每月提醒一次，告诉你本月还差多少',
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }

  tz.TZDateTime _nextInstance(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    while (!scheduled.isAfter(now)) {
      final m = scheduled.month + 1;
      final y = m > 12 ? scheduled.year + 1 : scheduled.year;
      scheduled = tz.TZDateTime(tz.local, y, m > 12 ? 1 : m, day, hour, minute);
    }
    return scheduled;
  }
}

/// 一条「某目标每月几号提醒」的描述
class GoalReminder {
  const GoalReminder({
    required this.name,
    required this.payDay,
    required this.body,
  });

  final String name;
  final int payDay;
  final String body;
}
