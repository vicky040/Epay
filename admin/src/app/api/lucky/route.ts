import { NextRequest } from 'next/server';

import { handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

const maskPhone = (p: string) =>
  p.length < 6 ? p : `${p.slice(0, 2)}****${p.slice(-4)}`;

export const GET = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const [prizes, wins] = await Promise.all([
    prisma.luckyPrize.findMany({ orderBy: { slot: 'asc' } }),
    prisma.luckyWin.findMany({
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: { user: { select: { phone: true } } },
    }),
  ]);

  return json({
    chances: user.drawChances,
    prizes: prizes.map((p) => ({ slot: p.slot, amount: p.amount })),
    wins: wins.map((w) => ({
      phone: maskPhone(w.user.phone),
      amount: w.amount,
      createdAt: w.createdAt,
    })),
  });
});
