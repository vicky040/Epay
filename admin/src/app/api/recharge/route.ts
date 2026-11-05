import { NextRequest } from 'next/server';
import { z } from 'zod';

import { fail, handler, json, round2, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { getSettings } from '@/lib/earnings';

const Body = z.object({
  amount: z.number().positive(),
  method: z.string().max(20).default('upi'),
});

export const POST = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const { amount, method } = Body.parse(await req.json());
  const settings = await getSettings();
  const min = Number(settings.minRecharge ?? 100);

  if (amount < min) return fail(`Minimum recharge is ₹${min}`, 422);

  // Deposits stay pending until an admin confirms the bank credit.
  await prisma.transaction.create({
    data: {
      userId: user.id,
      type: 'recharge',
      amount: round2(amount),
      status: 'pending',
      method,
      note: 'Awaiting confirmation',
    },
  });

  return json({
    ok: true,
    message: 'Recharge request submitted. It will be credited once confirmed.',
  });
});
