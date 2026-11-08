import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_info.dart';
import '../core/settings.dart';
import '../data/database.dart';
import '../state/providers.dart';
import 'palette.dart';
import 'widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Palette.of(context);
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final goals = ref.watch(goalsProvider).asData?.value ?? const <GoalRow>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
          children: [
            Text(
              '设置',
              style: TextStyle(
                color: p.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 3),
            Text('外观、提醒与数据', style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(height: 18),

            const SectionTitle('外观'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined, size: 17),
                        label: Text('跟随系统'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined, size: 17),
                        label: Text('浅色'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined, size: 17),
                        label: Text('深色'),
                      ),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => ctrl.setThemeMode(v.first),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '深色是默认配色；浅色适合白天和截图分享。',
                    style: TextStyle(color: p.faint, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const SectionTitle('月度提醒'),
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: s.reminderEnabled,
                    onChanged: (v) async {
                      if (v) {
                        final ok = await ref
                            .read(reminderServiceProvider)
                            .requestPermission();
                        if (!context.mounted) return;
                        await ctrl.setReminder(enabled: true);
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('系统通知权限没给，可能收不到提醒')),
                          );
                        }
                      } else {
                        await ctrl.setReminder(enabled: false);
                      }
                    },
                    title: Text(
                      '每月提醒我存钱',
                      style: TextStyle(color: p.text, fontSize: 14),
                    ),
                    subtitle: Text(
                      s.reminderEnabled
                          ? '下次：每月 ${s.reminderDay} 号 ${_two(s.reminderHour)}:${_two(s.reminderMinute)}'
                          : '打开后到日子会收到一条通知',
                      style: TextStyle(color: p.faint, fontSize: 11.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  if (s.reminderEnabled) ...[
                    Divider(height: 1, color: p.border),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: Text(
                        '提醒日期',
                        style: TextStyle(color: p.text, fontSize: 13.5),
                      ),
                      trailing: Text(
                        '每月 ${s.reminderDay} 号',
                        style: TextStyle(color: p.muted, fontSize: 12.5),
                      ),
                      onTap: () => _pickDay(context, ref, s.reminderDay, ctrl),
                    ),
                    Divider(height: 1, color: p.border),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: Text(
                        '提醒时间',
                        style: TextStyle(color: p.text, fontSize: 13.5),
                      ),
                      trailing: Text(
                        '${_two(s.reminderHour)}:${_two(s.reminderMinute)}',
                        style: TextStyle(color: p.muted, fontSize: 12.5),
                      ),
                      onTap: () => _pickTime(context, ref, s, ctrl),
                    ),
                    Divider(height: 1, color: p.border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextOutlinedButton(
                              label: '发一条测试通知',
                              icon: Icons.notifications_active_outlined,
                              onTap: () async {
                                await ref
                                    .read(reminderServiceProvider)
                                    .showNow(
                                      body:
                                          '本月还差 ${_shortfallText(ref)} 元，别忘了存',
                                    );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已发送，去看通知栏')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            const SectionTitle('数据'),
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: Icon(
                      Icons.auto_awesome_outlined,
                      size: 19,
                      color: p.blue,
                    ),
                    title: Text(
                      '导入示例数据',
                      style: TextStyle(color: p.text, fontSize: 13.5),
                    ),
                    subtitle: Text(
                      '两个目标 + 几条流水，用来体验补缴逻辑',
                      style: TextStyle(color: p.faint, fontSize: 11),
                    ),
                    onTap: () async {
                      await ref.read(repositoryProvider).seedDemo();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('示例数据已导入')));
                    },
                  ),
                  Divider(height: 1, color: p.border),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: p.danger,
                    ),
                    title: Text(
                      '清空全部数据',
                      style: TextStyle(color: p.danger, fontSize: 13.5),
                    ),
                    subtitle: Text(
                      '删除所有目标和流水，不可恢复',
                      style: TextStyle(color: p.faint, fontSize: 11),
                    ),
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('清空全部数据？'),
                          content: Text('${goals.length} 个目标和它们的流水都会被删除。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                '清空',
                                style: TextStyle(color: p.danger),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      final repo = ref.read(repositoryProvider);
                      for (final g in goals) {
                        await repo.deleteGoal(g.id);
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('已清空')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const SectionTitle('关于'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: Icons.donut_large_rounded,
                        color: p.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppInfo.name,
                              style: TextStyle(
                                color: p.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v${AppInfo.version} · 本地存储，不联网',
                              style: TextStyle(color: p.faint, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: '作者', value: AppInfo.author),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'QQ',
                    value: AppInfo.qq,
                    onTap: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: AppInfo.qq),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('QQ 号已复制')));
                    },
                  ),
                  const SizedBox(height: 14),
                  Divider(color: p.border, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    '每一期「应存额」由目标总额和期限算出，欠缴在上月末结算，'
                    '所以历史月份的应存额永远不变，只有未来月份会随补缴重算。',
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 11.5,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _shortfallText(WidgetRef ref) {
    final shortfall = ref.read(monthShortfallProvider);
    if (shortfall <= 0) return '0.00';
    return (shortfall / 100).toStringAsFixed(2);
  }

  Future<void> _pickDay(
    BuildContext context,
    WidgetRef ref,
    int current,
    SettingsController ctrl,
  ) async {
    final p = Palette.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '每月几号提醒',
                style: TextStyle(
                  color: p.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '只到 28 号，保证每个月都有这一天',
                style: TextStyle(color: p.faint, fontSize: 11),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 1; d <= 28; d++)
                    InkWell(
                      onTap: () => Navigator.pop(context, d),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        width: 42,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: d == current
                              ? p.green.withValues(alpha: 0.16)
                              : p.card,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: d == current
                                ? p.green.withValues(alpha: 0.6)
                                : p.border,
                          ),
                        ),
                        child: Text(
                          '$d',
                          style: TextStyle(
                            color: d == current ? p.green : p.muted,
                            fontSize: 13,
                            fontWeight: d == current
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await ctrl.setReminder(day: picked);
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    AppSettings s,
    SettingsController ctrl,
  ) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute),
    );
    if (t != null) {
      await ctrl.setReminder(hour: t.hour, minute: t.minute);
    }
  }
}

/// 轻量描边按钮：设置页里放次要动作
class TextOutlinedButton extends StatelessWidget {
  const TextOutlinedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: p.muted),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(color: p.muted, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

/// 关于页里的「标签 + 值」一行，值可点（比如复制 QQ 号）
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: p.muted, fontSize: 12.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: onTap == null ? p.text : p.blue,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy_rounded, size: 13, color: p.blue),
          ],
        ),
      ),
    );
  }
}
