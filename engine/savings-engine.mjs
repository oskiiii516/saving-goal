/**
 * 储蓄目标引擎（Savings Goal Engine）
 * 纯逻辑、零依赖、可直接移植到 Dart / Kotlin / Swift。金额一律用「分」的整数运算。
 *
 * ── 设计要点 ─────────────────────────────────────────────
 * 1) 基准时间表（schedule）：总额 / 期内月数 = 每月基准额，最后一月吸收取整误差。
 *    历史月份的「计划额」永久固定 → 明细表不会因为后来补缴而漂移。
 * 2) 欠缴（arrears）：按「时间表累计应有 - 累计实存」在**上月末**结算，
 *    而不是本月实时结算。本月存款只影响「本月是否达成」，不影响本月目标额本身。
 * 3) 补缴方式（arrearsMode）三选一：
 *      catchUpNow 立刻补齐（压力集中在下个月）
 *      spread     摊到剩余月（默认，最平滑）
 *      tail       滚到最后一月一次性补（适合年终奖）
 * 4) 重排模式（model = 'rebase'）：不看时间表，直接把「还差多少 / 还剩几个月」重新均摊，
 *    超出进度就自动减负。适合「只看结果不看节奏」的人。
 * ────────────────────────────────────────────────────────
 */

export function ymIndex(ym) {
  const [y, m] = ym.split('-').map(Number);
  return y * 12 + (m - 1);
}

export function indexYm(i) {
  return `${Math.floor(i / 12)}-${String((i % 12) + 1).padStart(2, '0')}`;
}

export function monthsInclusive(fromYm, toYm) {
  return ymIndex(toYm) - ymIndex(fromYm) + 1;
}

export function todayYm(now = new Date()) {
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

export function fmt(cents) {
  const s = cents < 0 ? '-' : '';
  const v = Math.abs(cents);
  return `${s}${Math.floor(v / 100)}.${String(v % 100).padStart(2, '0')}`;
}

export const MODEL = { SCHEDULE: 'schedule', REBASE: 'rebase' };
export const ARREARS = { SPREAD: 'spread', NOW: 'catchUpNow', TAIL: 'tail' };

/** 时间表：返回每个月的基准额（最后一月吸收余数） */
export function buildSchedule(goal) {
  const n = Math.max(1, monthsInclusive(goal.startYm, goal.deadlineYm));
  const per = Math.floor(goal.targetCents / n);
  const rows = [];
  for (let i = 0; i < n; i++) rows.push(per);
  rows[n - 1] += goal.targetCents - per * n; // 余数给最后一月
  return rows;
}

/**
 * @param {object} goal { id,name,targetCents,startYm,deadlineYm,
 *                        model='schedule', arrearsMode='spread', graceMonths=0 }
 * @param {Array}  deposits [{ goalId, ym, amountCents, note }]
 * @param {string} nowYm 'YYYY-MM'
 */
export function computeGoal(goal, deposits, nowYm) {
  const target = goal.targetCents;
  const startIdx = ymIndex(goal.startYm);
  const endIdx = ymIndex(goal.deadlineYm);
  const nowIdx = ymIndex(nowYm);
  const totalMonths = monthsInclusive(goal.startYm, goal.deadlineYm);
  const model = goal.model ?? MODEL.SCHEDULE;
  const arrearsMode = goal.arrearsMode ?? ARREARS.SPREAD;
  const grace = Math.max(0, goal.graceMonths ?? 0);

  const schedule = buildSchedule(goal);
  const baseMonthly = schedule[0];

  const mine = deposits.filter((d) => d.goalId === goal.id);
  const byMonth = new Map();
  for (const d of mine) byMonth.set(d.ym, (byMonth.get(d.ym) ?? 0) + d.amountCents);

  const sumMonths = (fromIdx, toIdx) => {
    let s = 0;
    for (let i = fromIdx; i <= toIdx; i++) s += byMonth.get(indexYm(i)) ?? 0;
    return s;
  };

  const savedTotal = mine.reduce((s, d) => s + d.amountCents, 0);
  const savedThisMonth = byMonth.get(nowYm) ?? 0;
  const savedBefore = sumMonths(startIdx, nowIdx - 1);
  const gap = Math.max(0, target - savedTotal);
  const over = Math.max(0, savedTotal - target);

  // 时间表在「上月末」的累计应有（只算已进入的期数）
  const settledMonths = Math.max(0, Math.min(nowIdx - startIdx, totalMonths)); // 上月末已完成期数
  let scheduledCumBefore = 0;
  for (let k = 0; k < settledMonths; k++) scheduledCumBefore += schedule[k];

  const arrears = Math.max(0, scheduledCumBefore - savedBefore);
  const monthsLeftInclThis = Math.max(0, endIdx - nowIdx + 1);
  const monthsAfterThis = Math.max(0, monthsLeftInclThis - 1);

  // ── 本期基准额 ──
  const baseThisMonth =
    nowIdx < startIdx ? 0 : nowIdx > endIdx ? 0 : schedule[Math.min(nowIdx - startIdx, schedule.length - 1)];

  // ── 本月应存额 ──
  let required = 0;
  let catchUp = 0;
  let basis = '';

  if (savedTotal >= target) {
    basis = `已完成${over ? `，超出 ${fmt(over)}` : ''}`;
  } else if (nowIdx > endIdx) {
    required = gap;
    basis = '期限已过，缺口全额补';
  } else if (nowIdx < startIdx) {
    basis = `计划 ${goal.startYm} 开始`;
  } else if (model === MODEL.REBASE) {
    // 重排：把（目标 - 上月末已存）均摊到剩余月份（含本月）
    const remaining = Math.max(1, monthsLeftInclThis - grace);
    required = Math.ceil(Math.max(0, target - savedBefore) / remaining);
    catchUp = required - baseThisMonth;
    basis = `重排：还差 ${fmt(Math.max(0, target - savedBefore))} / 剩 ${remaining} 个月`;
  } else {
    catchUp = 0;
    if (arrears > 0 && monthsAfterThis > 0) {
      if (arrearsMode === ARREARS.NOW) {
        catchUp = arrears;
        basis = `基准 ${fmt(baseThisMonth)} + 补缴 ${fmt(arrears)}`;
      } else if (arrearsMode === ARREARS.SPREAD) {
        const spreadable = Math.max(1, monthsAfterThis - grace);
        catchUp = Math.ceil(arrears / spreadable);
        basis = `基准 ${fmt(baseThisMonth)} + 补缴 ${fmt(catchUp)}（${fmt(arrears)} 摊 ${spreadable} 月）`;
      } else {
        catchUp = 0;
        basis = `基准 ${fmt(baseThisMonth)}，${fmt(arrears)} 留到末期补齐`;
      }
    } else if (arrears > 0) {
      catchUp = arrears;
      basis = `基准 ${fmt(baseThisMonth)} + 末期补齐 ${fmt(arrears)}`;
    } else {
      basis = `基准 ${fmt(baseThisMonth)}`;
    }
    required = Math.min(gap, Math.max(0, baseThisMonth + catchUp));
  }

  // ── 月度明细 ──
  const months = [];
  let cumPlanned = 0;
  let cumActual = 0;
  const upper = Math.max(endIdx, nowIdx);
  for (let i = startIdx; i <= upper; i++) {
    const ym = indexYm(i);
    const actual = byMonth.get(ym) ?? 0;
    const isPast = i < nowIdx;
    const isCurrent = i === nowIdx;
    const schedIdx = i - startIdx;
    const schedBase = schedIdx >= 0 && schedIdx < schedule.length ? schedule[schedIdx] : 0;

    let planned;
    if (isPast) planned = schedBase;
    else if (isCurrent) planned = required;
    else planned = schedBase;

    cumPlanned += planned;
    cumActual += actual;
    months.push({
      ym,
      plannedCents: planned,
      actualCents: actual,
      deltaCents: actual - planned,
      cumPlannedCents: cumPlanned,
      cumActualCents: cumActual,
      isPast,
      isCurrent,
      isFuture: i > nowIdx,
    });
  }

  // ── 状态 ──
  let status;
  if (savedTotal >= target) status = 'done';
  else if (nowIdx > endIdx) status = 'overdue';
  else if (nowIdx < startIdx) status = 'notStarted';
  else if (savedThisMonth >= required) status = 'onTrack';
  else status = 'behind';

  // ── 按当前节奏预计完成月 ──
  let projectedFinishYm = null;
  if (status === 'done') projectedFinishYm = nowYm;
  else if (status === 'overdue') projectedFinishYm = null;
  else {
    const pace = Math.max(required, baseThisMonth, 1);
    const needMonths = Math.ceil(Math.max(0, target - savedTotal) / pace);
    projectedFinishYm = indexYm(nowIdx + needMonths);
  }

  return {
    goalId: goal.id,
    name: goal.name,
    targetCents: target,
    savedTotalCents: savedTotal,
    gapCents: gap,
    overCents: over,
    progress: target > 0 ? Math.min(1, savedTotal / target) : 0,
    totalMonths,
    monthsLeftInclThis,
    baseMonthlyCents: baseMonthly,
    arrearsCents: arrears,
    requiredThisMonthCents: required,
    paidThisMonthCents: savedThisMonth,
    scheduledCumBeforeCents: scheduledCumBefore,
    basis,
    status,
    projectedFinishYm,
    months,
  };
}

export function aggregate(plans) {
  return plans.reduce(
    (a, p) => {
      a.requiredThisMonthCents += p.requiredThisMonthCents;
      a.savedTotalCents += p.savedTotalCents;
      a.targetCents += p.targetCents;
      a.gapCents += p.gapCents;
      if (p.status === 'behind') a.behindCount++;
      if (p.status === 'done') a.doneCount++;
      if (p.status === 'overdue') a.overdueCount++;
      return a;
    },
    { requiredThisMonthCents: 0, savedTotalCents: 0, targetCents: 0, gapCents: 0, behindCount: 0, doneCount: 0, overdueCount: 0 }
  );
}
