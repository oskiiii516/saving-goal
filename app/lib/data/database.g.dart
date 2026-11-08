// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetCentsMeta = const VerificationMeta(
    'targetCents',
  );
  @override
  late final GeneratedColumn<int> targetCents = GeneratedColumn<int>(
    'target_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialCentsMeta = const VerificationMeta(
    'initialCents',
  );
  @override
  late final GeneratedColumn<int> initialCents = GeneratedColumn<int>(
    'initial_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startYmMeta = const VerificationMeta(
    'startYm',
  );
  @override
  late final GeneratedColumn<String> startYm = GeneratedColumn<String>(
    'start_ym',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadlineYmMeta = const VerificationMeta(
    'deadlineYm',
  );
  @override
  late final GeneratedColumn<String> deadlineYm = GeneratedColumn<String>(
    'deadline_ym',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('schedule'),
  );
  static const VerificationMeta _arrearsModeMeta = const VerificationMeta(
    'arrearsMode',
  );
  @override
  late final GeneratedColumn<String> arrearsMode = GeneratedColumn<String>(
    'arrears_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('spread'),
  );
  static const VerificationMeta _graceMonthsMeta = const VerificationMeta(
    'graceMonths',
  );
  @override
  late final GeneratedColumn<int> graceMonths = GeneratedColumn<int>(
    'grace_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _payDayMeta = const VerificationMeta('payDay');
  @override
  late final GeneratedColumn<int> payDay = GeneratedColumn<int>(
    'pay_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetCents,
    initialCents,
    startYm,
    deadlineYm,
    model,
    arrearsMode,
    graceMonths,
    priority,
    payDay,
    note,
    archived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_cents')) {
      context.handle(
        _targetCentsMeta,
        targetCents.isAcceptableOrUnknown(
          data['target_cents']!,
          _targetCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetCentsMeta);
    }
    if (data.containsKey('initial_cents')) {
      context.handle(
        _initialCentsMeta,
        initialCents.isAcceptableOrUnknown(
          data['initial_cents']!,
          _initialCentsMeta,
        ),
      );
    }
    if (data.containsKey('start_ym')) {
      context.handle(
        _startYmMeta,
        startYm.isAcceptableOrUnknown(data['start_ym']!, _startYmMeta),
      );
    } else if (isInserting) {
      context.missing(_startYmMeta);
    }
    if (data.containsKey('deadline_ym')) {
      context.handle(
        _deadlineYmMeta,
        deadlineYm.isAcceptableOrUnknown(data['deadline_ym']!, _deadlineYmMeta),
      );
    } else if (isInserting) {
      context.missing(_deadlineYmMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('arrears_mode')) {
      context.handle(
        _arrearsModeMeta,
        arrearsMode.isAcceptableOrUnknown(
          data['arrears_mode']!,
          _arrearsModeMeta,
        ),
      );
    }
    if (data.containsKey('grace_months')) {
      context.handle(
        _graceMonthsMeta,
        graceMonths.isAcceptableOrUnknown(
          data['grace_months']!,
          _graceMonthsMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('pay_day')) {
      context.handle(
        _payDayMeta,
        payDay.isAcceptableOrUnknown(data['pay_day']!, _payDayMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_cents'],
      )!,
      initialCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_cents'],
      )!,
      startYm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_ym'],
      )!,
      deadlineYm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deadline_ym'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      arrearsMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arrears_mode'],
      )!,
      graceMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grace_months'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      payDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pay_day'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final String id;
  final String name;
  final int targetCents;

  /// 建目标前就已经存下的钱（期初已存），不计入任何月份
  final int initialCents;

  /// 'YYYY-MM'
  final String startYm;
  final String deadlineYm;

  /// schedule | rebase
  final String model;

  /// spread | catchUpNow | tail
  final String arrearsMode;
  final int graceMonths;

  /// 分配优先级：数字小的先满足（补缴建议按这个顺序给钱）
  final int priority;

  /// 每月几号存这笔钱并提醒（1–28；0 = 不单独提醒）
  final int payDay;
  final String note;
  final bool archived;
  final DateTime createdAt;
  const GoalRow({
    required this.id,
    required this.name,
    required this.targetCents,
    required this.initialCents,
    required this.startYm,
    required this.deadlineYm,
    required this.model,
    required this.arrearsMode,
    required this.graceMonths,
    required this.priority,
    required this.payDay,
    required this.note,
    required this.archived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['target_cents'] = Variable<int>(targetCents);
    map['initial_cents'] = Variable<int>(initialCents);
    map['start_ym'] = Variable<String>(startYm);
    map['deadline_ym'] = Variable<String>(deadlineYm);
    map['model'] = Variable<String>(model);
    map['arrears_mode'] = Variable<String>(arrearsMode);
    map['grace_months'] = Variable<int>(graceMonths);
    map['priority'] = Variable<int>(priority);
    map['pay_day'] = Variable<int>(payDay);
    map['note'] = Variable<String>(note);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetCents: Value(targetCents),
      initialCents: Value(initialCents),
      startYm: Value(startYm),
      deadlineYm: Value(deadlineYm),
      model: Value(model),
      arrearsMode: Value(arrearsMode),
      graceMonths: Value(graceMonths),
      priority: Value(priority),
      payDay: Value(payDay),
      note: Value(note),
      archived: Value(archived),
      createdAt: Value(createdAt),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetCents: serializer.fromJson<int>(json['targetCents']),
      initialCents: serializer.fromJson<int>(json['initialCents']),
      startYm: serializer.fromJson<String>(json['startYm']),
      deadlineYm: serializer.fromJson<String>(json['deadlineYm']),
      model: serializer.fromJson<String>(json['model']),
      arrearsMode: serializer.fromJson<String>(json['arrearsMode']),
      graceMonths: serializer.fromJson<int>(json['graceMonths']),
      priority: serializer.fromJson<int>(json['priority']),
      payDay: serializer.fromJson<int>(json['payDay']),
      note: serializer.fromJson<String>(json['note']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetCents': serializer.toJson<int>(targetCents),
      'initialCents': serializer.toJson<int>(initialCents),
      'startYm': serializer.toJson<String>(startYm),
      'deadlineYm': serializer.toJson<String>(deadlineYm),
      'model': serializer.toJson<String>(model),
      'arrearsMode': serializer.toJson<String>(arrearsMode),
      'graceMonths': serializer.toJson<int>(graceMonths),
      'priority': serializer.toJson<int>(priority),
      'payDay': serializer.toJson<int>(payDay),
      'note': serializer.toJson<String>(note),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GoalRow copyWith({
    String? id,
    String? name,
    int? targetCents,
    int? initialCents,
    String? startYm,
    String? deadlineYm,
    String? model,
    String? arrearsMode,
    int? graceMonths,
    int? priority,
    int? payDay,
    String? note,
    bool? archived,
    DateTime? createdAt,
  }) => GoalRow(
    id: id ?? this.id,
    name: name ?? this.name,
    targetCents: targetCents ?? this.targetCents,
    initialCents: initialCents ?? this.initialCents,
    startYm: startYm ?? this.startYm,
    deadlineYm: deadlineYm ?? this.deadlineYm,
    model: model ?? this.model,
    arrearsMode: arrearsMode ?? this.arrearsMode,
    graceMonths: graceMonths ?? this.graceMonths,
    priority: priority ?? this.priority,
    payDay: payDay ?? this.payDay,
    note: note ?? this.note,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetCents: data.targetCents.present
          ? data.targetCents.value
          : this.targetCents,
      initialCents: data.initialCents.present
          ? data.initialCents.value
          : this.initialCents,
      startYm: data.startYm.present ? data.startYm.value : this.startYm,
      deadlineYm: data.deadlineYm.present
          ? data.deadlineYm.value
          : this.deadlineYm,
      model: data.model.present ? data.model.value : this.model,
      arrearsMode: data.arrearsMode.present
          ? data.arrearsMode.value
          : this.arrearsMode,
      graceMonths: data.graceMonths.present
          ? data.graceMonths.value
          : this.graceMonths,
      priority: data.priority.present ? data.priority.value : this.priority,
      payDay: data.payDay.present ? data.payDay.value : this.payDay,
      note: data.note.present ? data.note.value : this.note,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetCents: $targetCents, ')
          ..write('initialCents: $initialCents, ')
          ..write('startYm: $startYm, ')
          ..write('deadlineYm: $deadlineYm, ')
          ..write('model: $model, ')
          ..write('arrearsMode: $arrearsMode, ')
          ..write('graceMonths: $graceMonths, ')
          ..write('priority: $priority, ')
          ..write('payDay: $payDay, ')
          ..write('note: $note, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetCents,
    initialCents,
    startYm,
    deadlineYm,
    model,
    arrearsMode,
    graceMonths,
    priority,
    payDay,
    note,
    archived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetCents == this.targetCents &&
          other.initialCents == this.initialCents &&
          other.startYm == this.startYm &&
          other.deadlineYm == this.deadlineYm &&
          other.model == this.model &&
          other.arrearsMode == this.arrearsMode &&
          other.graceMonths == this.graceMonths &&
          other.priority == this.priority &&
          other.payDay == this.payDay &&
          other.note == this.note &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> targetCents;
  final Value<int> initialCents;
  final Value<String> startYm;
  final Value<String> deadlineYm;
  final Value<String> model;
  final Value<String> arrearsMode;
  final Value<int> graceMonths;
  final Value<int> priority;
  final Value<int> payDay;
  final Value<String> note;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetCents = const Value.absent(),
    this.initialCents = const Value.absent(),
    this.startYm = const Value.absent(),
    this.deadlineYm = const Value.absent(),
    this.model = const Value.absent(),
    this.arrearsMode = const Value.absent(),
    this.graceMonths = const Value.absent(),
    this.priority = const Value.absent(),
    this.payDay = const Value.absent(),
    this.note = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String name,
    required int targetCents,
    this.initialCents = const Value.absent(),
    required String startYm,
    required String deadlineYm,
    this.model = const Value.absent(),
    this.arrearsMode = const Value.absent(),
    this.graceMonths = const Value.absent(),
    this.priority = const Value.absent(),
    this.payDay = const Value.absent(),
    this.note = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetCents = Value(targetCents),
       startYm = Value(startYm),
       deadlineYm = Value(deadlineYm),
       createdAt = Value(createdAt);
  static Insertable<GoalRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? targetCents,
    Expression<int>? initialCents,
    Expression<String>? startYm,
    Expression<String>? deadlineYm,
    Expression<String>? model,
    Expression<String>? arrearsMode,
    Expression<int>? graceMonths,
    Expression<int>? priority,
    Expression<int>? payDay,
    Expression<String>? note,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetCents != null) 'target_cents': targetCents,
      if (initialCents != null) 'initial_cents': initialCents,
      if (startYm != null) 'start_ym': startYm,
      if (deadlineYm != null) 'deadline_ym': deadlineYm,
      if (model != null) 'model': model,
      if (arrearsMode != null) 'arrears_mode': arrearsMode,
      if (graceMonths != null) 'grace_months': graceMonths,
      if (priority != null) 'priority': priority,
      if (payDay != null) 'pay_day': payDay,
      if (note != null) 'note': note,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? targetCents,
    Value<int>? initialCents,
    Value<String>? startYm,
    Value<String>? deadlineYm,
    Value<String>? model,
    Value<String>? arrearsMode,
    Value<int>? graceMonths,
    Value<int>? priority,
    Value<int>? payDay,
    Value<String>? note,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetCents: targetCents ?? this.targetCents,
      initialCents: initialCents ?? this.initialCents,
      startYm: startYm ?? this.startYm,
      deadlineYm: deadlineYm ?? this.deadlineYm,
      model: model ?? this.model,
      arrearsMode: arrearsMode ?? this.arrearsMode,
      graceMonths: graceMonths ?? this.graceMonths,
      priority: priority ?? this.priority,
      payDay: payDay ?? this.payDay,
      note: note ?? this.note,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetCents.present) {
      map['target_cents'] = Variable<int>(targetCents.value);
    }
    if (initialCents.present) {
      map['initial_cents'] = Variable<int>(initialCents.value);
    }
    if (startYm.present) {
      map['start_ym'] = Variable<String>(startYm.value);
    }
    if (deadlineYm.present) {
      map['deadline_ym'] = Variable<String>(deadlineYm.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (arrearsMode.present) {
      map['arrears_mode'] = Variable<String>(arrearsMode.value);
    }
    if (graceMonths.present) {
      map['grace_months'] = Variable<int>(graceMonths.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (payDay.present) {
      map['pay_day'] = Variable<int>(payDay.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetCents: $targetCents, ')
          ..write('initialCents: $initialCents, ')
          ..write('startYm: $startYm, ')
          ..write('deadlineYm: $deadlineYm, ')
          ..write('model: $model, ')
          ..write('arrearsMode: $arrearsMode, ')
          ..write('graceMonths: $graceMonths, ')
          ..write('priority: $priority, ')
          ..write('payDay: $payDay, ')
          ..write('note: $note, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DepositsTable extends Deposits
    with TableInfo<$DepositsTable, DepositRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DepositsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ymMeta = const VerificationMeta('ym');
  @override
  late final GeneratedColumn<String> ym = GeneratedColumn<String>(
    'ym',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    ym,
    amountCents,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deposits';
  @override
  VerificationContext validateIntegrity(
    Insertable<DepositRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('ym')) {
      context.handle(_ymMeta, ym.isAcceptableOrUnknown(data['ym']!, _ymMeta));
    } else if (isInserting) {
      context.missing(_ymMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DepositRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DepositRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      ym: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ym'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DepositsTable createAlias(String alias) {
    return $DepositsTable(attachedDatabase, alias);
  }
}

class DepositRow extends DataClass implements Insertable<DepositRow> {
  final String id;
  final String goalId;
  final String ym;
  final int amountCents;
  final String note;
  final DateTime createdAt;
  const DepositRow({
    required this.id,
    required this.goalId,
    required this.ym,
    required this.amountCents,
    required this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['ym'] = Variable<String>(ym);
    map['amount_cents'] = Variable<int>(amountCents);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DepositsCompanion toCompanion(bool nullToAbsent) {
    return DepositsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      ym: Value(ym),
      amountCents: Value(amountCents),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory DepositRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DepositRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      ym: serializer.fromJson<String>(json['ym']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'ym': serializer.toJson<String>(ym),
      'amountCents': serializer.toJson<int>(amountCents),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DepositRow copyWith({
    String? id,
    String? goalId,
    String? ym,
    int? amountCents,
    String? note,
    DateTime? createdAt,
  }) => DepositRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    ym: ym ?? this.ym,
    amountCents: amountCents ?? this.amountCents,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  DepositRow copyWithCompanion(DepositsCompanion data) {
    return DepositRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      ym: data.ym.present ? data.ym.value : this.ym,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DepositRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('ym: $ym, ')
          ..write('amountCents: $amountCents, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, ym, amountCents, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DepositRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.ym == this.ym &&
          other.amountCents == this.amountCents &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class DepositsCompanion extends UpdateCompanion<DepositRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> ym;
  final Value<int> amountCents;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DepositsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.ym = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DepositsCompanion.insert({
    required String id,
    required String goalId,
    required String ym,
    required int amountCents,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       ym = Value(ym),
       amountCents = Value(amountCents),
       createdAt = Value(createdAt);
  static Insertable<DepositRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? ym,
    Expression<int>? amountCents,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (ym != null) 'ym': ym,
      if (amountCents != null) 'amount_cents': amountCents,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DepositsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? ym,
    Value<int>? amountCents,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DepositsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      ym: ym ?? this.ym,
      amountCents: amountCents ?? this.amountCents,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (ym.present) {
      map['ym'] = Variable<String>(ym.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DepositsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('ym: $ym, ')
          ..write('amountCents: $amountCents, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $DepositsTable deposits = $DepositsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [goals, deposits];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'goals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('deposits', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  required String name,
  required int targetCents,
  Value<int> initialCents,
  required String startYm,
  required String deadlineYm,
  Value<String> model,
  Value<String> arrearsMode,
  Value<int> graceMonths,
  Value<int> priority,
  Value<int> payDay,
  Value<String> note,
  Value<bool> archived,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> targetCents,
  Value<int> initialCents,
  Value<String> startYm,
  Value<String> deadlineYm,
  Value<String> model,
  Value<String> arrearsMode,
  Value<int> graceMonths,
  Value<int> priority,
  Value<int> payDay,
  Value<String> note,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, GoalRow> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DepositsTable, List<DepositRow>>
  _depositsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.deposits,
    aliasName: 'goals__id__deposits__goal_id',
  );

  $$DepositsTableProcessedTableManager get depositsRefs {
    final manager = $$DepositsTableTableManager(
      $_db,
      $_db.deposits,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_depositsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialCents => $composableBuilder(
    column: $table.initialCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startYm => $composableBuilder(
    column: $table.startYm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deadlineYm => $composableBuilder(
    column: $table.deadlineYm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arrearsMode => $composableBuilder(
    column: $table.arrearsMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get graceMonths => $composableBuilder(
    column: $table.graceMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payDay => $composableBuilder(
    column: $table.payDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> depositsRefs(
    Expression<bool> Function($$DepositsTableFilterComposer f) f,
  ) {
    final $$DepositsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deposits,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DepositsTableFilterComposer(
            $db: $db,
            $table: $db.deposits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialCents => $composableBuilder(
    column: $table.initialCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startYm => $composableBuilder(
    column: $table.startYm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deadlineYm => $composableBuilder(
    column: $table.deadlineYm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arrearsMode => $composableBuilder(
    column: $table.arrearsMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get graceMonths => $composableBuilder(
    column: $table.graceMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payDay => $composableBuilder(
    column: $table.payDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get initialCents => $composableBuilder(
    column: $table.initialCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startYm =>
      $composableBuilder(column: $table.startYm, builder: (column) => column);

  GeneratedColumn<String> get deadlineYm => $composableBuilder(
    column: $table.deadlineYm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get arrearsMode => $composableBuilder(
    column: $table.arrearsMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get graceMonths => $composableBuilder(
    column: $table.graceMonths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get payDay =>
      $composableBuilder(column: $table.payDay, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> depositsRefs<T extends Object>(
    Expression<T> Function($$DepositsTableAnnotationComposer a) f,
  ) {
    final $$DepositsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deposits,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DepositsTableAnnotationComposer(
            $db: $db,
            $table: $db.deposits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRow, $$GoalsTableReferences),
          GoalRow,
          PrefetchHooks Function({bool depositsRefs})
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> targetCents = const Value.absent(),
                Value<int> initialCents = const Value.absent(),
                Value<String> startYm = const Value.absent(),
                Value<String> deadlineYm = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> arrearsMode = const Value.absent(),
                Value<int> graceMonths = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> payDay = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                targetCents: targetCents,
                initialCents: initialCents,
                startYm: startYm,
                deadlineYm: deadlineYm,
                model: model,
                arrearsMode: arrearsMode,
                graceMonths: graceMonths,
                priority: priority,
                payDay: payDay,
                note: note,
                archived: archived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int targetCents,
                Value<int> initialCents = const Value.absent(),
                required String startYm,
                required String deadlineYm,
                Value<String> model = const Value.absent(),
                Value<String> arrearsMode = const Value.absent(),
                Value<int> graceMonths = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> payDay = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                targetCents: targetCents,
                initialCents: initialCents,
                startYm: startYm,
                deadlineYm: deadlineYm,
                model: model,
                arrearsMode: arrearsMode,
                graceMonths: graceMonths,
                priority: priority,
                payDay: payDay,
                note: note,
                archived: archived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, GoalRow>(table),
                  $$GoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({depositsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (depositsRefs) db.deposits],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (depositsRefs)
                    await $_getPrefetchedDataByColumns<
                      GoalRow,
                      $GoalsTable,
                      DepositRow,
                      $DepositsTable
                    >(
                      currentTable: table,
                      referencedTable: $$GoalsTableReferences
                          ._depositsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$GoalsTableReferences(db, table, p0).depositsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'goal_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRow, $$GoalsTableReferences),
      GoalRow,
      PrefetchHooks Function({bool depositsRefs})
    >;
typedef $$DepositsTableCreateCompanionBuilder = DepositsCompanion Function({
  required String id,
  required String goalId,
  required String ym,
  required int amountCents,
  Value<String> note,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DepositsTableUpdateCompanionBuilder = DepositsCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<String> ym,
  Value<int> amountCents,
  Value<String> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$DepositsTableReferences
    extends BaseReferences<_$AppDatabase, $DepositsTable, DepositRow> {
  $$DepositsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('deposits__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DepositsTableFilterComposer
    extends Composer<_$AppDatabase, $DepositsTable> {
  $$DepositsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ym => $composableBuilder(
    column: $table.ym,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DepositsTableOrderingComposer
    extends Composer<_$AppDatabase, $DepositsTable> {
  $$DepositsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ym => $composableBuilder(
    column: $table.ym,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DepositsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DepositsTable> {
  $$DepositsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ym =>
      $composableBuilder(column: $table.ym, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DepositsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DepositsTable,
          DepositRow,
          $$DepositsTableFilterComposer,
          $$DepositsTableOrderingComposer,
          $$DepositsTableAnnotationComposer,
          $$DepositsTableCreateCompanionBuilder,
          $$DepositsTableUpdateCompanionBuilder,
          (DepositRow, $$DepositsTableReferences),
          DepositRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$DepositsTableTableManager(_$AppDatabase db, $DepositsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DepositsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DepositsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DepositsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> ym = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DepositsCompanion(
                id: id,
                goalId: goalId,
                ym: ym,
                amountCents: amountCents,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String ym,
                required int amountCents,
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DepositsCompanion.insert(
                id: id,
                goalId: goalId,
                ym: ym,
                amountCents: amountCents,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DepositsTable, DepositRow>(table),
                  $$DepositsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$DepositsTableReferences._goalIdTable(
                          db,
                        ),
                        referencedColumn: $$DepositsTableReferences
                            ._goalIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DepositsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DepositsTable,
      DepositRow,
      $$DepositsTableFilterComposer,
      $$DepositsTableOrderingComposer,
      $$DepositsTableAnnotationComposer,
      $$DepositsTableCreateCompanionBuilder,
      $$DepositsTableUpdateCompanionBuilder,
      (DepositRow, $$DepositsTableReferences),
      DepositRow,
      PrefetchHooks Function({bool goalId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$DepositsTableTableManager get deposits =>
      $$DepositsTableTableManager(_db, _db.deposits);
}
