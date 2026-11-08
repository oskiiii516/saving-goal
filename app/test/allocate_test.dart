import 'package:flutter_test/flutter_test.dart';
import 'package:saving_goal/core/allocate.dart';
import 'package:saving_goal/core/engine.dart';

GoalComputation _plan({
  required String id,
  required int requiredThisMonth,
  required int paidThisMonth,
  required int gap,
}) {
  return GoalComputation(
    goalId: id,
    name: id,
    targetCents: gap + paidThisMonth,
    initialCents: 0,
    savedTotalCents: paidThisMonth,
    gapCents: gap,
    overCents: 0,
    progress: 0,
    totalMonths: 12,
    monthsLeftInclThis: 9,
    baseMonthlyCents: requiredThisMonth,
    arrearsCents: 0,
    requiredThisMonthCents: requiredThisMonth,
    paidThisMonthCents: paidThisMonth,
    scheduledCumBeforeCents: 0,
    basis: '',
    status: GoalStatus.onTrack,
    projectedFinishYm: '2027-08',
    months: const [],
  );
}

void main() {
  // A 本月还欠 1000（已存 0），总缺口 5000
  // B 本月已满（应存 1500 已存 1500），总缺口 3000
  final a = _plan(id: 'A', requiredThisMonth: 100000, paidThisMonth: 0, gap: 500000);
  final b = _plan(id: 'B', requiredThisMonth: 150000, paidThisMonth: 150000, gap: 300000);
  final plans = [a, b];

  test('预算为 0 时不分配任何钱', () {
    final r = allocate(plans, 0);
    expect(r.assignedCents, 0);
    expect(r.items.every((i) => i.suggestedCents == 0), isTrue);
    expect(r.satisfiedCount, 0);
  });

  test('预算不够补满时，按顺序给第一个，差额正确', () {
    final r = allocate(plans, 40000, allowAdvance: false);
    expect(r.items[0].suggestedCents, 40000);
    expect(r.items[0].stillShortThisMonth, 60000);
    expect(r.items[0].meetsThisMonth, isFalse);
    expect(r.items[1].suggestedCents, 0);
    expect(r.unassignedCents, 0);
  });

  test('预算刚好补满本月缺口，多的一分不进第二轮', () {
    final r = allocate(plans, 100000);
    expect(r.items[0].suggestedCents, 100000);
    expect(r.items[0].meetsThisMonth, isTrue);
    expect(r.items[1].suggestedCents, 0);
    expect(r.assignedCents, 100000);
    expect(r.fullyAssigned, isTrue);
    expect(r.satisfiedCount, 1);
  });

  test('预算有富余时按缺口比例预存，钱全部安排出去', () {
    final r = allocate(plans, 250000);
    expect(r.assignedCents, 250000);
    expect(r.unassignedCents, 0);
    expect(r.items[0].suggestedCents, greaterThan(100000));
    expect(r.items[1].suggestedCents, greaterThan(0));
  });

  test('关掉预存后，富余的钱原样留着', () {
    final r = allocate(plans, 250000, allowAdvance: false);
    expect(r.items[0].suggestedCents, 100000);
    expect(r.items[1].suggestedCents, 0);
    expect(r.assignedCents, 100000);
    expect(r.unassignedCents, 150000);
    expect(r.fullyAssigned, isFalse);
  });

  test('分配总额绝不会超过目标缺口', () {
    final r = allocate(plans, 10000000);
    // A 缺口 5000 + B 缺口 3000 = 8000 元
    expect(r.assignedCents, 800000);
    expect(r.unassignedCents, 10000000 - 800000);
    expect(r.items[0].suggestedCents, 500000);
    expect(r.items[1].suggestedCents, 300000);
  });

  test('负预算按 0 处理', () {
    final r = allocate(plans, -500);
    expect(r.budgetCents, 0);
    expect(r.assignedCents, 0);
  });
}
