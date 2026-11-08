import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine.dart';
import '../data/repository.dart';
import '../state/providers.dart';
import 'palette.dart';
import 'widgets.dart';

Future<void> showDepositFormSheet(
  BuildContext context,
  WidgetRef ref, {
  required SavingsGoal goal,
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
    builder: (_) => _DepositFormSheet(goal: goal),
  );
}

class _DepositFormSheet extends ConsumerStatefulWidget {
  const _DepositFormSheet({required this.goal});

  final SavingsGoal goal;

  @override
  ConsumerState<_DepositFormSheet> createState() => _DepositFormSheetState();
}

class _DepositFormSheetState extends ConsumerState<_DepositFormSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _ym;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final nowYm = ref.read(nowYmProvider);
    _ym = nowYm;
    final plan = ref.read(computationProvider(widget.goal.id));
    final suggest = plan?.remainingThisMonthCents ?? 0;
    _amount = TextEditingController(
      text: suggest > 0 ? SavingsEngine.fmt(suggest) : '',
    );
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cents = parseYuanToCents(_amount.text);
    if (cents == null || cents <= 0) {
      setState(() => _error = '填个正数金额，最多两位小数');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(repositoryProvider).addDeposit(
            goalId: widget.goal.id,
            ym: _ym,
            amountCents: cents,
            note: _note.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final comp = ref.watch(computationProvider(widget.goal.id));
    final remaining = comp?.remainingThisMonthCents ?? 0;
    final required = comp?.requiredThisMonthCents ?? 0;
    final paid = comp?.paidThisMonthCents ?? 0;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('存入 · ${widget.goal.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, size: 20, color: p.muted),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 2, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.cardHi,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Text('本月应存 ${SavingsEngine.fmt(required)}',
                      style: TextStyle(color: p.muted, fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('已存 ${SavingsEngine.fmt(paid)}',
                      style: TextStyle(color: p.green, fontSize: 12)),
                  const Spacer(),
                  Text(
                    remaining > 0 ? '还差 ${SavingsEngine.fmt(remaining)}' : '已达标',
                    style: TextStyle(
                        color: remaining > 0 ? p.warn : p.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: TextStyle(
                color: p.text,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '存入金额',
                hintText: '1000',
                suffixText: '元',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (remaining > 0)
                  _QuickChip(
                    label: '补齐本月 ${SavingsEngine.fmt(remaining)}',
                    onTap: () => setState(() =>
                        _amount.text = SavingsEngine.fmt(remaining)),
                  ),
                _QuickChip(
                  label: '基准月供',
                  onTap: () => setState(() =>
                      _amount.text = SavingsEngine.fmt(comp?.baseMonthlyCents ?? 0)),
                ),
                _QuickChip(
                  label: '500',
                  onTap: () => setState(() => _amount.text = '500.00'),
                ),
                _QuickChip(
                  label: '1000',
                  onTap: () => setState(() => _amount.text = '1000.00'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MonthPickerField(
              label: '记到哪个月',
              value: _ym,
              onChanged: (v) => setState(() => _ym = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              style: TextStyle(color: p.text),
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '可选，比如「年终奖」「这个月手紧」',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: p.danger, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? '保存中…' : '确认存入'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.cardHi,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: p.border),
        ),
        child: Text(label,
            style: TextStyle(color: p.muted, fontSize: 12)),
      ),
    );
  }
}
