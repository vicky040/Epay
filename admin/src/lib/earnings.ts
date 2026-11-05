import { prisma } from './db';
import { round2 } from './api';

/**
 * Credits any investment cycles that have elapsed since the last payout.
 *
 * Called lazily whenever a user's data is read, so balances are always current
 * without needing a background worker. Idempotent: a cycle is only ever paid
 * once because `cyclesPaid` is the source of truth.
 */
export async function accrueEarnings(userId: string) {
  const orders = await prisma.order.findMany({
    where: { userId, status: 'active' },
  });
  if (orders.length === 0) return;

  const now = Date.now();
  let totalCredited = 0;

  for (const o of orders) {
    const cycleMs =
      o.cycleUnit === 'Hours' ? 60 * 60 * 1000 : 24 * 60 * 60 * 1000;
    const start = o.createdAt.getTime();
    const elapsed = Math.floor((now - start) / cycleMs);
    const due = Math.min(elapsed, o.duration) - o.cyclesPaid;

    if (due <= 0) continue;

    const payout = round2(o.periodEarning * o.shares * due);
    const cyclesPaid = o.cyclesPaid + due;
    const finished = cyclesPaid >= o.duration;

    await prisma.order.update({
      where: { id: o.id },
      data: {
        cyclesPaid,
        earnedSoFar: round2(o.earnedSoFar + payout),
        status: finished ? 'finished' : 'active',
        lastPayoutAt: new Date(),
      },
    });

    await prisma.transaction.create({
      data: {
        userId,
        type: 'income',
        amount: payout,
        status: 'success',
        note: `${o.productTitle} · ${due} cycle${due === 1 ? '' : 's'}`,
      },
    });

    totalCredited += payout;
  }

  if (totalCredited > 0) {
    await prisma.user.update({
      where: { id: userId },
      data: {
        withdrawBalance: { increment: round2(totalCredited) },
        productIncome: { increment: round2(totalCredited) },
      },
    });
  }
}

/** Recomputes a user's VIP level from their lifetime invested total. */
export async function syncVipLevel(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;

  const tiers = await prisma.vipTier.findMany({ orderBy: { level: 'asc' } });
  let level = 0;
  for (const t of tiers) {
    if (user.totalInvested >= t.requiredAmount) level = t.level;
  }
  if (level !== user.vipLevel) {
    await prisma.user.update({ where: { id: userId }, data: { vipLevel: level } });
  }
}

/**
 * Pays the 3-level referral rebate for a purchase.
 * Level percentages come from Settings so the admin can tune them.
 */
export async function payReferralRebates(buyerId: string, amount: number) {
  const settings = await getSettings();
  const rates = [
    Number(settings.rebateL1 ?? 60),
    Number(settings.rebateL2 ?? 4),
    Number(settings.rebateL3 ?? 1),
  ];

  let currentId: string | null = buyerId;

  for (let level = 0; level < 3; level++) {
    const child: { referredById: string | null } | null =
      await prisma.user.findUnique({
        where: { id: currentId as string },
        select: { referredById: true },
      });
    if (!child?.referredById) break;

    const rebate = round2((amount * rates[level]) / 100);
    if (rebate > 0) {
      await prisma.user.update({
        where: { id: child.referredById },
        data: { withdrawBalance: { increment: rebate } },
      });
      await prisma.transaction.create({
        data: {
          userId: child.referredById,
          type: 'rebate',
          amount: rebate,
          status: 'success',
          note: `Level ${level + 1} team rebate`,
        },
      });
    }
    currentId = child.referredById;
  }
}

/** Bumps a task's progress counter for a user, creating the row if needed. */
export async function bumpTask(userId: string, key: string, by = 1) {
  const task = await prisma.task.findUnique({ where: { key } });
  if (!task || !task.active) return;

  const existing = await prisma.taskProgress.findUnique({
    where: { userId_taskId: { userId, taskId: task.id } },
  });

  if (existing) {
    if (existing.progress >= task.target) return;
    await prisma.taskProgress.update({
      where: { id: existing.id },
      data: { progress: Math.min(existing.progress + by, task.target) },
    });
  } else {
    await prisma.taskProgress.create({
      data: { userId, taskId: task.id, progress: Math.min(by, task.target) },
    });
  }
}

export type SettingsMap = Record<string, string>;

export async function getSettings(): Promise<SettingsMap> {
  const rows = await prisma.setting.findMany();
  return Object.fromEntries(rows.map((r) => [r.key, r.value]));
}

export async function setSetting(key: string, value: string) {
  await prisma.setting.upsert({
    where: { key },
    update: { value },
    create: { key, value },
  });
}

export const DEFAULT_SETTINGS: SettingsMap = {
  appName: 'EPay',
  activationReward: '100',
  rebateL1: '60',
  rebateL2: '4',
  rebateL3: '1',
  minRecharge: '100',
  minWithdraw: '100',
  withdrawTaxPercent: '5',
  blogReward: '22',
  supportHours: '08:00 — 20:00 IST',
  telegramUrl: 'https://t.me/epay_official',
  publicUrl: 'https://epay.app',
};
