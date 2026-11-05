import { NextRequest } from 'next/server';

import { handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { getSettings } from '@/lib/earnings';

export const GET = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const settings = await getSettings();
  const rates = [
    Number(settings.rebateL1 ?? 60),
    Number(settings.rebateL2 ?? 4),
    Number(settings.rebateL3 ?? 1),
  ];

  // Walk the downline three levels deep.
  const levels: { level: number; rebatePercent: number; invited: number; active: number; earned: number }[] = [];
  let frontier = [user.id];

  for (let level = 1; level <= 3; level++) {
    const members = frontier.length
      ? await prisma.user.findMany({
          where: { referredById: { in: frontier } },
          select: { id: true, totalInvested: true },
        })
      : [];

    levels.push({
      level,
      rebatePercent: rates[level - 1],
      invited: members.length,
      active: members.filter((m) => m.totalInvested > 0).length,
      earned: 0,
    });
    frontier = members.map((m) => m.id);
  }

  const rebates = await prisma.transaction.aggregate({
    where: { userId: user.id, type: 'rebate', status: 'success' },
    _sum: { amount: true },
  });
  // Rebates are not stored per level; attribute the total to level 1 for display.
  if (levels[0]) levels[0].earned = rebates._sum.amount ?? 0;

  const base = settings.publicUrl ?? process.env.APP_PUBLIC_URL ?? 'https://epay.app';

  return json({
    inviteLink: `${base}/?invitation_code=${user.inviteCode}`,
    inviteCode: user.inviteCode,
    activationReward: Number(settings.activationReward ?? 100),
    levels,
  });
});
