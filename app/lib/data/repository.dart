import 'package:drift/drift.dart';

import '../core/engine.dart';
import 'database.dart';

/// 把数据库行映射成引擎模型（引擎只认纯数据，不认 drift 类型）
extension GoalRowMapper on GoalRow {
  SavingsGoal toModel() => SavingsGoal(
        id: id,
        name: name,
        targetCents: targetCents,
        initialCents: initialCents,
        startYm: startYm,
        deadlineYm: deadlineYm,
        model: SavingsModel.values.byName(model),
        arrearsMode: ArrearsMode.values.byName(arrearsMode),
        graceMonths: graceMonths,
        note: note,
        archived: archived,
        priority: priority,
        payDay: payDay,
        createdAt: createdAt,
      );
}

extension DepositRowMapper on DepositRow {
  Deposit toModel() => Deposit(
        id: id,
        goalId: goalId,
        ym: ym,
        amountCents: amountCents,
        note: note,
        createdAt: createdAt,
      );
}

/// 金额输入解析：只接受「元」的两位小数，全程整数分，绝不用 double 算钱。
/// 返回 null 表示格式非法。
int? parseYuanToCents(String input) {
  final t = input.trim().replaceAll(',', '').replaceAll('¥', '');
  if (t.isEmpty) return null;
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(t)) return null;
  final parts = t.split('.');
  final yuan = int.parse(parts[0]);
  final frac = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
  return yuan * 100 + int.parse(frac);
}

class SavingsRepository {
  SavingsRepository(this.db);

  final AppDatabase db;

  Future<void> createGoal({
    required String name,
    required int targetCents,
    int initialCents = 0,
    required String startYm,
    required String deadlineYm,
    SavingsModel model = SavingsModel.schedule,
    ArrearsMode arrearsMode = ArrearsMode.spread,
    int graceMonths = 0,
    String note = '',
    int priority = 0,
    int payDay = 0,
  }) {
    return db.upsertGoal(GoalsCompanion.insert(
      id: newId(),
      name: name,
      targetCents: targetCents,
      initialCents: Value(initialCents),
      startYm: startYm,
      deadlineYm: deadlineYm,
      model: Value(model.name),
      arrearsMode: Value(arrearsMode.name),
      graceMonths: Value(graceMonths),
      note: Value(note),
      priority: Value(priority),
      payDay: Value(payDay),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> updateGoal(SavingsGoal goal) {
    return db.upsertGoal(GoalsCompanion.insert(
      id: goal.id,
      name: goal.name,
      targetCents: goal.targetCents,
      initialCents: Value(goal.initialCents),
      startYm: goal.startYm,
      deadlineYm: goal.deadlineYm,
      model: Value(goal.model.name),
      arrearsMode: Value(goal.arrearsMode.name),
      graceMonths: Value(goal.graceMonths),
      note: Value(goal.note),
      archived: Value(goal.archived),
      priority: Value(goal.priority),
      payDay: Value(goal.payDay),
      createdAt: goal.createdAt,
    ));
  }

  Future<void> deleteGoal(String id) => db.deleteGoal(id);

  /// 重新排优先级：传入按顺序排好的目标 id
  Future<void> reorderGoals(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await db.setPriority(orderedIds[i], i);
    }
  }

  /// 一次把分配建议落成流水（一键补缴）
  Future<void> addDepositsBatch(List<({String goalId, String ym, int cents, String note})> items) async {
    for (final it in items) {
      if (it.cents <= 0) continue;
      await addDeposit(goalId: it.goalId, ym: it.ym, amountCents: it.cents, note: it.note);
    }
  }

  Future<void> addDeposit({
    required String goalId,
    required String ym,
    required int amountCents,
    String note = '',
  }) {
    return db.addDeposit(DepositsCompanion.insert(
      id: newId(),
      goalId: goalId,
      ym: ym,
      amountCents: amountCents,
      note: Value(note),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> deleteDeposit(String id) => db.deleteDeposit(id);

  /// 示例数据：两个目标 + 几笔存入，方便第一次打开就有东西可看
  Future<void> seedDemo() async {
    final now = DateTime.now();
    final yi = SavingsEngine.ymIndex(SavingsEngine.todayYm(now));

    await createGoal(
      name: '旅行基金',
      targetCents: 1200000,
      startYm: SavingsEngine.indexYm(yi - 3),
      deadlineYm: SavingsEngine.indexYm(yi + 8),
      note: '日本 · 往返机票+住宿',
    );
    await createGoal(
      name: '新电脑',
      targetCents: 900000,
      startYm: SavingsEngine.indexYm(yi),
      deadlineYm: SavingsEngine.indexYm(yi + 5),
      model: SavingsModel.rebase,
      note: 'MacBook',
    );

    final rows = await db.allGoals();
    final travel = rows.firstWhere((g) => g.name == '旅行基金');
    final laptop = rows.firstWhere((g) => g.name == '新电脑');

    await addDeposit(
        goalId: travel.id,
        ym: SavingsEngine.indexYm(yi - 3),
        amountCents: 100000,
        note: '首月');
    await addDeposit(
        goalId: travel.id,
        ym: SavingsEngine.indexYm(yi - 2),
        amountCents: 100000);
    await addDeposit(
        goalId: travel.id,
        ym: SavingsEngine.indexYm(yi - 1),
        amountCents: 40000,
        note: '这个月手紧');
    await addDeposit(
        goalId: laptop.id,
        ym: SavingsEngine.indexYm(yi),
        amountCents: 150000);
  }
}

String newId() {
  final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rnd = (DateTime.now().hashCode & 0xffff).toRadixString(36);
  return '$ts$rnd';
}
