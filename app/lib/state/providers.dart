import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/engine.dart';
import '../core/settings.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../services/reminder_service.dart';

/// 数据库单例
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<SavingsRepository>(
  (ref) => SavingsRepository(ref.watch(dbProvider)),
);

/// 所有目标（含归档）
final goalsProvider = StreamProvider<List<GoalRow>>(
  (ref) => ref.watch(dbProvider).watchGoals(),
);

/// 所有存入流水
final depositsProvider = StreamProvider<List<DepositRow>>(
  (ref) => ref.watch(dbProvider).watchDeposits(),
);

/// 当前月份 ym，UI 里可被「测试某个月」覆盖
final nowYmProvider = Provider<String>((ref) => SavingsEngine.todayYm());

/// 每个目标的完整计算（应存/实存/补缴/状态/月度明细）
final computationsProvider = Provider<List<GoalComputation>>((ref) {
  final goalRows = ref.watch(goalsProvider).asData?.value ?? const <GoalRow>[];
  final depositRows =
      ref.watch(depositsProvider).asData?.value ?? const <DepositRow>[];
  final nowYm = ref.watch(nowYmProvider);
  if (goalRows.isEmpty) return const [];

  final deposits = depositRows.map((r) => r.toModel()).toList(growable: false);
  final goals = goalRows.where((g) => !g.archived).toList()
    ..sort((a, b) {
      // 1) 用户手动排的优先级（拖动排序写入 0..n）
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      final ca = SavingsEngine.compute(a.toModel(), deposits, nowYm);
      final cb = SavingsEngine.compute(b.toModel(), deposits, nowYm);
      // 2) 未完成的排前面，3) 按月供从高到低
      final da = ca.status == GoalStatus.done ? 1 : 0;
      final dbg = cb.status == GoalStatus.done ? 1 : 0;
      if (da != dbg) return da - dbg;
      return cb.requiredThisMonthCents.compareTo(ca.requiredThisMonthCents);
    });

  return goals
      .map((g) => SavingsEngine.compute(g.toModel(), deposits, nowYm))
      .toList(growable: false);
});

/// 单目标计算（详情页用）
final computationProvider =
    Provider.family<GoalComputation?, String>((ref, goalId) {
  final list = ref.watch(computationsProvider);
  for (final c in list) {
    if (c.goalId == goalId) return c;
  }
  return null;
});

/// 汇总：本月总负担 / 已存 / 缺口
final aggregateProvider = Provider<Aggregate>(
  (ref) => SavingsEngine.aggregate(ref.watch(computationsProvider)),
);

/// 某目标的存入记录（倒序）
final depositsOfGoalProvider =
    Provider.family<List<Deposit>, String>((ref, goalId) {
  final rows = ref.watch(depositsProvider).asData?.value ?? const <DepositRow>[];
  final list = rows
      .where((r) => r.goalId == goalId)
      .map((r) => r.toModel())
      .toList()
    ..sort((a, b) {
      final c = b.ym.compareTo(a.ym);
      return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
    });
  return list;
});


// ─────────────────────────── 偏好设置 ───────────────────────────

/// 在 main() 里用真实实例 override
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider 需要在 ProviderScope 里 override'),
);

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = ReminderService();
  return service;
});

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final p = ref.watch(prefsProvider);
    return AppSettings(
      themeMode: AppSettings.parseThemeMode(p.getString('themeMode')),
      reminderEnabled: p.getBool('reminderEnabled') ?? false,
      reminderDay: p.getInt('reminderDay') ?? 5,
      reminderHour: p.getInt('reminderHour') ?? 9,
      reminderMinute: p.getInt('reminderMinute') ?? 0,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(prefsProvider).setString('themeMode', mode.name);
  }

  Future<void> setReminder({
    bool? enabled,
    int? day,
    int? hour,
    int? minute,
  }) async {
    state = state.copyWith(
      reminderEnabled: enabled,
      reminderDay: day,
      reminderHour: hour,
      reminderMinute: minute,
    );
    final p = ref.read(prefsProvider);
    await p.setBool('reminderEnabled', state.reminderEnabled);
    await p.setInt('reminderDay', state.reminderDay);
    await p.setInt('reminderHour', state.reminderHour);
    await p.setInt('reminderMinute', state.reminderMinute);
    await syncReminder();
  }

  /// 把当前设置 + 当前欠缴金额写进系统提醒（一条全局汇总 + 每个目标各自的提醒日）
  Future<void> syncReminder() async {
    final service = ref.read(reminderServiceProvider);
    if (!state.reminderEnabled) {
      await service.cancel();
      await service.syncGoalReminders(const [], state);
      return;
    }
    final agg = ref.read(aggregateProvider);
    final body = agg.behindCount > 0 || agg.requiredThisMonthCents > 0
        ? '本月还差 ${SavingsEngine.fmtMoney(agg.requiredThisMonthCents - agg.paidThisMonthCents)}，${agg.behindCount} 个目标没跟上'
        : '本月目标都跟上了，继续保持';
    await service.sync(state, body: body);

    // 每个设了「每月几号存」的目标，各排一条自己的提醒
    final plans = ref.read(computationsProvider);
    final items = <GoalReminder>[];
    for (final plan in plans) {
      if (plan.payDay < 1 || plan.payDay > 28) continue;
      if (plan.status == GoalStatus.done) continue;
      final need = plan.remainingThisMonthCents;
      items.add(GoalReminder(
        name: plan.name,
        payDay: plan.payDay,
        body: need > 0
            ? '今天该存 ${SavingsEngine.fmtMoney(need)} 了（还差 ${SavingsEngine.fmtMoney(plan.gapCents)}）'
            : '本月已存够，顺手看一眼进度吧',
      ));
    }
    await service.syncGoalReminders(items, state);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// 本月还差多少（给提醒文案与首页复用）
final monthShortfallProvider = Provider<int>((ref) {
  final agg = ref.watch(aggregateProvider);
  final v = agg.requiredThisMonthCents - agg.paidThisMonthCents;
  return v > 0 ? v : 0;
});
