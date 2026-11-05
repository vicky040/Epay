import { NextRequest } from 'next/server';
import { z } from 'zod';

import { handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

export const GET = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const card = await prisma.bankCard.findUnique({ where: { userId: user.id } });
  if (!card) return json(null);

  return json({
    holder: card.holder,
    accountNumber: card.accountNumber,
    ifsc: card.ifsc,
    bankName: card.bankName,
    upi: card.upi,
  });
});

const Body = z.object({
  holder: z.string().min(2).max(60),
  accountNumber: z.string().min(6).max(20),
  ifsc: z.string().min(6).max(15),
  bankName: z.string().min(2).max(60),
  upi: z.string().max(60).nullish(),
});

export const POST = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const body = Body.parse(await req.json());
  const data = {
    holder: body.holder,
    accountNumber: body.accountNumber,
    ifsc: body.ifsc.toUpperCase(),
    bankName: body.bankName,
    upi: body.upi ?? null,
  };

  await prisma.bankCard.upsert({
    where: { userId: user.id },
    update: data,
    create: { userId: user.id, ...data },
  });

  return json({ ok: true, message: 'Bank details saved' });
});
