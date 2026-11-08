import 'package:flutter/material.dart';

import '../core/engine.dart';
import 'palette.dart';

/// 等宽数字：金额变化时不会左右跳
class Money extends StatelessWidget {
  const Money(
    this.text, {
    super.key,
    this.size = 16,
    this.weight = FontWeight.w700,
    this.color,
    this.letterSpacing,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Text(
      text,
      style: TextStyle(
        color: color ?? p.text,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// 细进度条，带底色轨道和圆角
class SlimProgress extends StatelessWidget {
  const SlimProgress({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.background,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => LinearProgressIndicator(
          value: animated,
          minHeight: height,
          backgroundColor: background ?? p.cardHi,
          valueColor: AlwaysStoppedAnimation(color ?? p.green),
        ),
      ),
    );
  }
}

/// 状态徽章：按计划 / 本月欠缴 / 已还清 / 已逾期 / 未开始
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final GoalStatus status;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final color = switch (status) {
      GoalStatus.onTrack => p.green,
      GoalStatus.behind => p.warn,
      GoalStatus.done => p.blue,
      GoalStatus.overdue => p.danger,
      GoalStatus.notStarted => p.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, height: 1.25),
      ),
    );
  }
}

/// 「标签 + 金额」一组，用于卡片的 应存/已存/还差
class StatColumn extends StatelessWidget {
  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.align = CrossAxisAlignment.start,
    this.size = 16,
  });

  final String label;
  final String value;
  final Color? color;
  final CrossAxisAlignment align;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: p.muted, fontSize: 11)),
        const SizedBox(height: 5),
        Money(value, size: size, color: color ?? p.text),
      ],
    );
  }
}

/// 卡片壳：统一边框、圆角、内边距，可选渐变色
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.onTap,
    this.borderColor,
    this.gradient,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final r = BorderRadius.circular(radius);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? p.card) : null,
        gradient: gradient,
        borderRadius: r,
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: p.isDark ? 0 : 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Panel 自己画底色；里面的 ListTile / 按钮要靠 Material 才能画出水波纹，
      // 所以统一在这一层补一个透明 Material，别让调用方逐个去包
      child: Material(type: MaterialType.transparency, child: child),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: r, child: box),
    );
  }
}

/// 小节标题
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: p.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// 圆形图标底，给列表项做视觉锚点
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 38,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = color ?? p.green;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: size * 0.52, color: c),
    );
  }
}

/// 月份下拉：给表单用，返回 'YYYY-MM'
class MonthPickerField extends StatelessWidget {
  const MonthPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final idx = SavingsEngine.ymIndex(value);
    final months = [
      for (var i = -24; i <= 60; i++) SavingsEngine.indexYm(idx + i)
    ];
    if (!months.contains(value)) months.add(value);

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      dropdownColor: p.cardHi,
      style: TextStyle(color: p.text, fontSize: 14),
      items: [
        for (final m in months)
          DropdownMenuItem(
            value: m,
            child: Text(
              '${m.substring(0, 4)} 年 ${int.parse(m.substring(5))} 月',
              style: const TextStyle(fontFamily: kFontFamily),
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
