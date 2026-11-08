import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// 目标表：不存「每月应存额」——它永远由引擎现算，
/// 存下来就会和实际存入失配，这是记账类 App 的经典脏数据来源。
@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get targetCents => integer()();

  /// 建目标前就已经存下的钱（期初已存），不计入任何月份
  IntColumn get initialCents => integer().withDefault(const Constant(0))();

  /// 'YYYY-MM'
  TextColumn get startYm => text()();
  TextColumn get deadlineYm => text()();

  /// schedule | rebase
  TextColumn get model => text().withDefault(const Constant('schedule'))();

  /// spread | catchUpNow | tail
  TextColumn get arrearsMode => text().withDefault(const Constant('spread'))();

  IntColumn get graceMonths => integer().withDefault(const Constant(0))();

  /// 分配优先级：数字小的先满足（补缴建议按这个顺序给钱）
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// 每月几号存这笔钱并提醒（1–28；0 = 不单独提醒）
  IntColumn get payDay => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 存入流水：ym 是「归属月份」，支持补录历史月份
@DataClassName('DepositRow')
class Deposits extends Table {
  TextColumn get id => text()();
  TextColumn get goalId =>
      text().references(Goals, #id, onDelete: KeyAction.cascade)();
  TextColumn get ym => text()();
  IntColumn get amountCents => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Goals, Deposits])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(goals, goals.priority);
          }
          if (from < 3) {
            await m.addColumn(goals, goals.initialCents);
          }
          if (from < 4) {
            await m.addColumn(goals, goals.payDay);
          }
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(name: 'saving_goal');

  // ── 查询 ──
  Stream<List<GoalRow>> watchGoals() => (select(goals)
        ..where((t) => t.archived.equals(false))
        ..orderBy([
          (t) => OrderingTerm.asc(t.priority),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .watch();

  Stream<List<DepositRow>> watchDeposits() =>
      (select(deposits)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<GoalRow>> allGoals() => select(goals).get();
  Future<List<DepositRow>> allDeposits() => select(deposits).get();

  // ── 写入 ──
  Future<void> upsertGoal(GoalsCompanion row) =>
      into(goals).insertOnConflictUpdate(row);

  Future<void> setPriority(String id, int priority) =>
      (update(goals)..where((t) => t.id.equals(id)))
          .write(GoalsCompanion(priority: Value(priority)));

  Future<void> deleteGoal(String id) =>
      (delete(goals)..where((t) => t.id.equals(id))).go();

  Future<void> addDeposit(DepositsCompanion row) => into(deposits).insert(row);

  Future<void> deleteDeposit(String id) =>
      (delete(deposits)..where((t) => t.id.equals(id))).go();
}
