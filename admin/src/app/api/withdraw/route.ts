import { NextRequest } from 'next/server';
import { z } from 'zod';

import { fail, handler, json, round2, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { accrueEarnings, getSettings } from '@/lib/earnings';

const Body = z.object({ amount: z.number().positive() });

export const POST = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const { amount } = Body.parse(await req.json());
  const settings = await getSettings();
  const min = Number(settings.minWithdraw ?? 100);
  const taxPercent = Number(settings.withdrawTaxPercent ?? 5);

  if (amount < min) return fail(`Minimum withdrawal is ₹${min}`, 422);

  const card = await prisma.bankCard.findUnique({ where: { userId: user.id } });
  if (!card) return fail('Add your bank details before withdrawing', 422);

  await accrueEarnings(user.id);
  const fresh = await prisma.user.findUnique({ where: { id: user.id } });
  if (!fresh || fresh.withdrawBalance < amount) {
    return fail('Insufficient withdrawable balance', 402);
  }

  const tax = round2((amount * taxPercent) / 100);
  const net = round2(amount - tax);

  // Funds are held immediately; an admin approves or rejects the payout.
  await prisma.$transaction([
    prisma.user.update({
      where: { id: user.id },
      data: { withdrawBalance: { decrement: round2(amount) } },
    }),
    prisma.transaction.create({
      data: {
        userId: user.id,
        type: 'withdraw',
        amount: round2(amount),
        status: 'pending',
        note: `Tax ₹${tax} · You receive ₹${net}`,
      },
    }),
  ]);

  return json({
    ok: true,
    message: `Withdrawal of ₹${net} submitted and is being processed.`,
  });
});
