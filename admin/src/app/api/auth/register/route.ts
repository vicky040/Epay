import { NextRequest } from 'next/server';
import { z } from 'zod';

import { fail, handler, json } from '@/lib/api';
import { generateInviteCode, hashPassword, signAppToken } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { publicUser } from '@/lib/serialize';

const Body = z.object({
  phone: z.string().min(8).max(15),
  password: z.string().min(6).max(64),
  nickname: z.string().min(1).max(24),
  inviteCode: z.string().max(16).nullish(),
  otp: z.string().max(8).nullish(),
});

export const POST = handler(async (req: NextRequest) => {
  const body = Body.parse(await req.json());

  const existing = await prisma.user.findUnique({ where: { phone: body.phone } });
  if (existing) return fail('This phone number is already registered', 409);

  // Verify the OTP unless it has been switched off for development.
  if (process.env.SKIP_OTP !== 'true') {
    const otp = await prisma.otp.findFirst({
      where: {
        phone: body.phone,
        code: body.otp ?? '',
        consumed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    if (!otp) return fail('Invalid or expired verification code', 422);
    await prisma.otp.update({ where: { id: otp.id }, data: { consumed: true } });
  }

  let referredById: string | null = null;
  if (body.inviteCode) {
    const referrer = await prisma.user.findUnique({
      where: { inviteCode: body.inviteCode.toUpperCase() },
    });
    if (!referrer) return fail('Invalid invitation code', 422);
    referredById = referrer.id;
  }

  // Invite codes are unique; retry on the (rare) collision.
  let inviteCode = generateInviteCode();
  for (let i = 0; i < 5; i++) {
    const clash = await prisma.user.findUnique({ where: { inviteCode } });
    if (!clash) break;
    inviteCode = generateInviteCode();
  }

  const user = await prisma.user.create({
    data: {
      phone: body.phone,
      passwordHash: await hashPassword(body.password),
      nickname: body.nickname,
      inviteCode,
      referredById,
    },
  });

  return json({ token: signAppToken(user.id, user.phone), user: publicUser(user) });
});
