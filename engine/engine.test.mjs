import assert from 'node:assert/strict';
import { computeGoal, aggregate, MODEL, ARREARS, fmt, monthsInclusive, buildSchedule } from './savings-engine.mjs';

// 目标 12000 元 / 2026-01 ~ 2026-12，基准月供 1000
const goal = {
  id: 'g1',
  name: '旅行基金',
  targetCents: 1_200_000,
  startYm: '2026-01',
  deadlineYm: '2026-12',
  model: MODEL.SCHEDULE,
  arrearsMode: ARREARS.SPREAD,
};

const dep = (ym, yuan) => ({ goalId: 'g1', ym, amountCents: Math.round(yuan * 100) });

console.log('时间表:', buildSchedule(goal).join(','));
assert.equal(monthsInclusive('2026-01', '2026-12'), 12);

// 1 按时存
{
  const p = computeGoal(goal, [dep('2026-01', 1000), dep('2026-02', 1000)], '2026-02');
  assert.equal(p.requiredThisMonthCents, 100_000);
  assert.equal(p.status, 'onTrack');
  assert.equal(p.arrearsCents, 0);
  console.log('[1] 按时存：本月应存', fmt(p.requiredThisMonthCents), '状态', p.status);
}

// 2 本月少存 → 状态落后，缺口进 arrears
{
  const p = computeGoal(goal, [dep('2026-01', 1000), dep('2026-02', 500)], '2026-02');
  assert.equal(p.requiredThisMonthCents, 100_000); // 本月目标额不变
  assert.equal(p.paidThisMonthCents, 50_000);
  assert.equal(p.status, 'behind');
  console.log('[2] 2月只存500：本月目标', fmt(p.requiredThisMonthCents), '实存', fmt(p.paidThisMonthCents), p.status);
}

// 3 拖到 5 月，欠 2500 → 摊到剩余 7 个月
{
  const p = computeGoal(goal, [dep('2026-01', 1000), dep('2026-02', 500)], '2026-05');
  // 上月末(4月末)应有 4000，实存 1500 → 欠 2500；本月基准 1000；摊 7 月 → ceil(250000/7)=35715
  assert.equal(p.arrearsCents, 250_000);
  assert.equal(p.requiredThisMonthCents, 100_000 + 35_715);
  console.log('[3] 拖到5月：欠', fmt(p.arrearsCents), '→ 本月应存', fmt(p.requiredThisMonthCents), '|', p.basis);
}

// 4 三种补缴方式对比（同一起点）
{
  const now = '2026-05';
  const ds = [dep('2026-01', 1000), dep('2026-02', 500)];
  for (const m of Object.values(ARREARS)) {
    const p = computeGoal({ ...goal, arrearsMode: m }, ds, now);
    console.log(`[4] ${m.padEnd(11)} 本月应存 ${fmt(p.requiredThisMonthCents).padStart(9)} | ${p.basis}`);
  }
}

// 5 期限最后一个月必须补齐全部
{
  const p = computeGoal(goal, [], '2026-12');
  assert.equal(p.requiredThisMonthCents, 1_200_000); // 全期一分没存
  console.log('[5] 末期未存：应存', fmt(p.requiredThisMonthCents));
}

// 6 重排模式：大额存入自动减负
{
  const ds = [dep('2026-01', 1000), dep('2026-02', 5000)];
  const p = computeGoal({ ...goal, model: MODEL.REBASE }, ds, '2026-03');
  // 3 月起，上月末已存 6000，剩 10 个月 → 600/月
  assert.equal(p.requiredThisMonthCents, 60_000);
  console.log('[6] 重排模式：2月一次存5000 → 3月起每月', fmt(p.requiredThisMonthCents));
}

// 7 重排模式：欠缴自动摊平
{
  const ds = [dep('2026-01', 500)];
  const p = computeGoal({ ...goal, model: MODEL.REBASE }, ds, '2026-04');
  // 上月末已存 500，剩 9 个月 → ceil(11500/9)=1277.78 → 127778
  assert.equal(p.requiredThisMonthCents, 127_778);
  console.log('[7] 重排模式欠缴：本月应存', fmt(p.requiredThisMonthCents), '|', p.basis);
}

// 8 完成 / 超额
{
  const p = computeGoal(goal, [dep('2026-03', 13000)], '2026-03');
  assert.equal(p.status, 'done');
  assert.equal(p.overCents, 100_000);
  assert.equal(p.requiredThisMonthCents, 0);
  console.log('[8] 超额：', p.status, '超出', fmt(p.overCents));
}

// 9 逾期
{
  const p = computeGoal(goal, [dep('2026-01', 3000)], '2027-03');
  assert.equal(p.status, 'overdue');
  assert.equal(p.requiredThisMonthCents, 900_000);
  console.log('[9] 逾期：缺口全额', fmt(p.requiredThisMonthCents));
}

// 10 宽限期：欠缴不摊到前 N 个月
{
  const ds = [dep('2026-01', 1000)];
  const a = computeGoal({ ...goal, graceMonths: 0 }, ds, '2026-04');
  const b = computeGoal({ ...goal, graceMonths: 2 }, ds, '2026-04');
  console.log('[10] 宽限0 →', fmt(a.requiredThisMonthCents), '| 宽限2 →', fmt(b.requiredThisMonthCents));
  assert.ok(b.requiredThisMonthCents > a.requiredThisMonthCents);
}

// 11 多目标汇总
{
  const g2 = { id: 'g2', name: '买电脑', targetCents: 800_000, startYm: '2026-03', deadlineYm: '2026-08' };
  const plans = [
    computeGoal(goal, [dep('2026-01', 1000)], '2026-04'),
    computeGoal(g2, [], '2026-04'),
  ];
  const agg = aggregate(plans);
  console.log('[11] 多目标本月合计', fmt(agg.requiredThisMonthCents), '元');
  plans.forEach((p) => console.log(`     ${p.name}: 本月 ${fmt(p.requiredThisMonthCents)} / 总 ${fmt(p.targetCents)} / ${(p.progress * 100).toFixed(0)}%`));
  assert.equal(agg.requiredThisMonthCents, plans[0].requiredThisMonthCents + plans[1].requiredThisMonthCents);
}

// 12 逐月缴清：总额精确收敛，无累积误差
{
  const odd = { id: 'g3', name: '取整', targetCents: 100_000, startYm: '2026-01', deadlineYm: '2026-03' };
  console.log('[12] 时间表 1000元/3月 =', buildSchedule(odd).map(fmt).join(' + '));
  assert.equal(buildSchedule(odd).reduce((a, b) => a + b, 0), 100_000);
  const s = buildSchedule({ ...odd, targetCents: 100_001 });
  console.log('     1000.01元/3月 =', s.map(fmt).join(' + '), '(末月吸收余数)');
  assert.equal(s.reduce((a, b) => a + b, 0), 100_001);
}

// 13 中途修改目标金额，历史不变、未来自动重算
{
  const p = computeGoal({ ...goal, targetCents: 1_800_000 }, [dep('2026-01', 1000), dep('2026-02', 1000)], '2026-06');
  console.log('[13] 目标提到18000：6月应存', fmt(p.requiredThisMonthCents), '| 基准', fmt(p.baseMonthlyCents), '|', p.basis);
}

console.log('\n✅ 全部断言通过');
