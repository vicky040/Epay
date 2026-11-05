import { NextRequest } from 'next/server';

import { fail, handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

export const POST = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  if (user.drawChances <= 0) return fail('No draws remaining', 409);

  const prizes = await prisma.luckyPrize.findMany({ orderBy: { slot: 'asc' } });
  if (prizes.length === 0) return fail('No prizes configured', 503);

  // Weighted pick — smaller prizes carry the larger weights.
  const total = prizes.reduce((s, p) => s + Math.max(p.weight, 0), 0) || 1;
  let r = Math.random() * total;
  let picked = prizes[prizes.length - 1];
  for (const p of prizes) {
    r -= Math.max(p.weight, 0);
    if (r <= 0) {
      picked = p;
      break;
    }
  }

  await prisma.$transaction([
    prisma.user.update({
      where: { id: user.id },
      data: {
        drawChances: { decrement: 1 },
        withdrawBalance: { increment: picked.amount },
      },
    }),
    prisma.luckyWin.create({
      data: { userId: user.id, slot: picked.slot, amount: picked.amount },
    }),
    prisma.transaction.create({
      data: {
        userId: user.id,
        type: 'bonus',
        amount: picked.amount,
        status: 'success',
        note: 'Lucky wheel',
      },
    }),
  ]);

  return json({ ok: true, slot: picked.slot, amount: picked.amount });
});
