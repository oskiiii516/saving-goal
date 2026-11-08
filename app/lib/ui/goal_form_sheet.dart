import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine.dart';
import '../data/repository.dart';
import '../state/providers.dart';
import 'palette.dart';
import 'widgets.dart';

Future<void> showGoalFormSheet(
  BuildContext context,
  WidgetRef ref, {
  SavingsGoal? editing,
}) {
  final p = Palette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.bg,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _GoalFormSheet(editing: editing),
  );
}

class _GoalFormSheet extends ConsumerStatefulWidget {
  const _GoalFormSheet({this.editing});

  final SavingsGoal? editing;

  @override
  ConsumerState<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<_GoalFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _initial;
  late final TextEditingController _note;
  late final TextEditingController _monthly;
  late String _startYm;
  late String _deadlineYm;
  late ArrearsMode _arrears;
  late SavingsModel _model;
  late _PlanMode _mode;
  late int _payDay;
  String? _error;
  bool _saving = false;

  bool get isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.editing;
    final nowYm = ref.read(nowYmProvider);
    _name = TextEditingController(text: g?.name ?? '');
    _amount = TextEditingController(
        text: g == null ? '' : SavingsEngine.fmt(g.targetCents));
    _initial = TextEditingController(
        text: (g == null || g.initialCents == 0)
            ? ''
            : SavingsEngine.fmt(g.initialCents));
    _monthly = TextEditingController();
    _mode = _PlanMode.byDeadline;
    _payDay = g?.payDay ?? 0;
    _note = TextEditingController(text: g?.note ?? '');
    _startYm = g?.startYm ?? nowYm;
    _deadlineYm = g?.deadlineYm ??
        SavingsEngine.indexYm(SavingsEngine.ymIndex(nowYm) + 11);
    _arrears = g?.arrearsMode ?? ArrearsMode.spread;
    _model = g?.model ?? SavingsModel.schedule;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _initial.dispose();
    _note.dispose();
    _monthly.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final cents = parseYuanToCents(_amount.text);
    if (name.isEmpty) {
      setState(() => _error = '给目标起个名字');
      return;
    }
    if (cents == null || cents <= 0) {
      setState(() => _error = '金额填个正数，最多两位小数');
      return;
    }
    final initialCents = _initial.text.trim().isEmpty
        ? 0
        : parseYuanToCents(_initial.text);
    if (initialCents == null) {
      setState(() => _error = '「已经存了」填个数字，两位小数以内，没存就留空');
      return;
    }
    if (initialCents >= cents) {
      setState(() => _error = '已经存的钱要不小于目标金额，这个目标已经完成了');
      return;
    }

    // 按每月能存多少反推截止月份
    var deadlineYm = _deadlineYm;
    if (_mode == _PlanMode.byMonthly) {
      final monthlyCents = parseYuanToCents(_monthly.text);
      if (monthlyCents == null || monthlyCents <= 0) {
        setState(() => _error = '填一下每月能存多少，正数，两位小数以内');
        return;
      }
      final n = SavingsEngine.monthsNeeded(cents, monthlyCents,
          initialCents: initialCents);
      if (n <= 0) {
        setState(() => _error = '每月金额得大于 0');
        return;
      }
      if (n > 600) {
        setState(() => _error = '按这个月供要 $n 个月（50 年），换个金额试试');
        return;
      }
      deadlineYm = SavingsEngine.deadlineFor(
        targetCents: cents,
        monthlyCents: monthlyCents,
        startYm: _startYm,
        initialCents: initialCents,
      );
    } else if (SavingsEngine.ymIndex(_deadlineYm) <
        SavingsEngine.ymIndex(_startYm)) {
      setState(() => _error = '截止月份不能早于开始月份');
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    final repo = ref.read(repositoryProvider);
    try {
      if (isEdit) {
        await repo.updateGoal(widget.editing!.copyWith(
          name: name,
          targetCents: cents,
          initialCents: initialCents,
          startYm: _startYm,
          deadlineYm: deadlineYm,
          arrearsMode: _arrears,
          model: _model,
          note: _note.text.trim(),
          payDay: _payDay,
        ));
      } else {
        await repo.createGoal(
          name: name,
          targetCents: cents,
          initialCents: initialCents,
          startYm: _startYm,
          deadlineYm: deadlineYm,
          arrearsMode: _arrears,
          model: _model,
          note: _note.text.trim(),
          payDay: _payDay,
        );
      }
      // 设了「每月几号存」就确保提醒是开着的，否则用户会以为提醒没生效
      if (_payDay >= 1 && _payDay <= 28) {
        await ref.read(reminderServiceProvider).requestPermission();
        if (!ref.read(settingsProvider).reminderEnabled) {
          await ref.read(settingsProvider.notifier).setReminder(enabled: true);
        }
      }
      // 目标变了，重排提醒（每月几号存可能改了）
      await ref.read(settingsProvider.notifier).syncReminder();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final months = SavingsEngine.monthsInclusive(_startYm, _deadlineYm);
    final cents = parseYuanToCents(_amount.text) ?? 0;
    final initial = _initial.text.trim().isEmpty
        ? 0
        : (parseYuanToCents(_initial.text) ?? 0);
    final remaining = (cents - initial).clamp(0, cents);
    final per = remaining > 0 && months > 0 ? (remaining / months).round() : 0;

    // 反向规划：按每月能存的钱推出月数
    final monthlyCents = parseYuanToCents(_monthly.text) ?? 0;
    final plannedMonths =
        SavingsEngine.monthsNeeded(cents, monthlyCents, initialCents: initial);
    final plannedDeadline = plannedMonths > 0
        ? SavingsEngine.deadlineFor(
            targetCents: cents,
            monthlyCents: monthlyCents,
            startYm: _startYm,
            initialCents: initial,
          )
        : _startYm;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(isEdit ? '编辑目标' : '新建储蓄目标',
                    style: TextStyle(
                        color: p.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 20, color: p.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              style: TextStyle(color: p.text),
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: '目标名称',
                hintText: '如 旅行基金 / 换电脑 / 应急金',
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: TextStyle(
                color: p.text,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '目标金额',
                hintText: '12000',
                suffixText: '元',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _initial,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: TextStyle(color: p.text, fontSize: 17),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '已经存了多少（可选）',
                hintText: '开始前已经在账上的钱，比如 5000',
                helperText: '这部分不参与按月分摊，只从总额里扣掉',
                suffixText: '元',
              ),
            ),
            const SizedBox(height: 16),
            Text('怎么定计划',
                style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(height: 8),
            SegmentedButton<_PlanMode>(
              segments: const [
                ButtonSegment(
                  value: _PlanMode.byDeadline,
                  label: Text('先定期限'),
                  icon: Icon(Icons.event_available_outlined, size: 16),
                ),
                ButtonSegment(
                  value: _PlanMode.byMonthly,
                  label: Text('先定月供'),
                  icon: Icon(Icons.savings_outlined, size: 16),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
            const SizedBox(height: 12),
            if (_mode == _PlanMode.byDeadline) ...[
              Row(
                children: [
                  Expanded(
                    child: MonthPickerField(
                      label: '开始月份',
                      value: _startYm,
                      onChanged: (v) => setState(() {
                        _startYm = v;
                        if (SavingsEngine.ymIndex(_deadlineYm) <
                            SavingsEngine.ymIndex(_startYm)) {
                          _deadlineYm = v;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MonthPickerField(
                      label: '截止月份',
                      value: _deadlineYm,
                      onChanged: (v) => setState(() => _deadlineYm = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                months > 0
                    ? (initial > 0
                        ? '还要存 ¥${SavingsEngine.fmt(remaining)}，共 $months 个月，平均每月 ¥${SavingsEngine.fmt(per)}'
                        : '共 $months 个月，平均每月 ¥${SavingsEngine.fmt(per)}')
                    : '截止月份需晚于开始月份',
                style: TextStyle(
                  color: months > 0 ? p.green : p.danger,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _monthly,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: TextStyle(
                        color: p.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: '每月能存多少',
                        hintText: '5000',
                        suffixText: '元/月',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MonthPickerField(
                      label: '开始月份',
                      value: _startYm,
                      onChanged: (v) => setState(() => _startYm = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cents <= 0
                    ? '先填目标金额，这里自动算要存多久'
                    : (monthlyCents <= 0
                        ? '填每月能存的钱，自动算出存多久'
                        : (plannedMonths > 0
                            ? '需要 $plannedMonths 个月：$_startYm 起，$plannedDeadline 完成'
                            : '每月金额得大于 0')),
                style: TextStyle(
                  color: monthlyCents > 0 && plannedMonths > 0
                      ? p.green
                      : p.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _PayDayField(
              value: _payDay,
              onChanged: (v) => setState(() => _payDay = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ArrearsMode>(
              initialValue: _arrears,
              dropdownColor: p.cardHi,
              style: TextStyle(color: p.text, fontSize: 14),
              decoration: const InputDecoration(labelText: '存少了怎么补'),
              items: const [
                DropdownMenuItem(
                    value: ArrearsMode.spread,
                    child: Text('摊到剩余每个月（推荐，最平滑）',
                        style: TextStyle(fontFamily: kFontFamily))),
                DropdownMenuItem(
                    value: ArrearsMode.catchUpNow,
                    child: Text('下个月一次补齐',
                        style: TextStyle(fontFamily: kFontFamily))),
                DropdownMenuItem(
                    value: ArrearsMode.tail,
                    child: Text('先欠着，留到末期补',
                        style: TextStyle(fontFamily: kFontFamily))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _arrears = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SavingsModel>(
              initialValue: _model,
              dropdownColor: p.cardHi,
              style: TextStyle(color: p.text, fontSize: 14),
              decoration: const InputDecoration(labelText: '计算方式'),
              items: const [
                DropdownMenuItem(
                    value: SavingsModel.schedule,
                    child: Text('固定月供（欠了才补）',
                        style: TextStyle(fontFamily: kFontFamily))),
                DropdownMenuItem(
                    value: SavingsModel.rebase,
                    child: Text('滚动重排（每月重算）',
                        style: TextStyle(fontFamily: kFontFamily))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _model = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              style: TextStyle(color: p.text),
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '可选',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 14, color: p.danger),
                  const SizedBox(width: 6),
                  Text(_error!,
                      style: TextStyle(color: p.danger, fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? '保存中…' : (isEdit ? '保存' : '创建')),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PlanMode { byDeadline, byMonthly }

/// 每月几号存这笔钱（同时作为这条目标的提醒日）
class _PayDayField extends StatelessWidget {
  const _PayDayField({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: p.cardHi,
      style: TextStyle(color: p.text, fontSize: 14),
      decoration: const InputDecoration(labelText: '每月几号存'),
      items: [
        const DropdownMenuItem(
            value: 0,
            child: Text('不单独提醒（跟随全局设置）',
                style: TextStyle(fontFamily: kFontFamily))),
        for (var d = 1; d <= 28; d++)
          DropdownMenuItem(
              value: d,
              child: Text('每月 $d 号',
                  style: const TextStyle(fontFamily: kFontFamily))),
      ],
      onChanged: (v) => onChanged(v ?? 0),
    );
  }
}
