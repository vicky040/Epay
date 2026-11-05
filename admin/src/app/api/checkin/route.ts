import { NextRequest } from 'next/server';

import { fail, handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { bumpTask } from '@/lib/earnings';

const isSameDay = (a: Date, b: Date) =>
  a.getFullYear() === b.getFullYear() &&
  a.getMonth() === b.getMonth() &&
  a.getDate() === b.getDate();

export const POST = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  if (user.lastCheckIn && isSameDay(user.lastCheckIn, new Date())) {
    return fail('You have already checked in today', 409);
  }

  const tier = await prisma.vipTier.findUnique({ where: { level: user.vipLevel } });
  const reward = tier?.dailyBonus ?? 0;

  await prisma.user.update({
    where: { id: user.id },
    data: {
      lastCheckIn: new Date(),
      ...(reward > 0 ? { withdrawBalance: { increment: reward } } : {}),
    },
  });

  if (reward > 0) {
    await prisma.transaction.create({
      data: {
        userId: user.id,
        type: 'bonus',
        amount: reward,
        status: 'success',
        note: 'Daily check-in',
      },
    });
  }

  await bumpTask(user.id, 'checkin_streak');

  return json({ ok: true, reward });
});
