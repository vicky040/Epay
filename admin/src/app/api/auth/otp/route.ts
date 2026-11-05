import { NextRequest } from 'next/server';
import { z } from 'zod';

import { generateOtp } from '@/lib/auth';
import { fail, handler, json } from '@/lib/api';
import { prisma } from '@/lib/db';

const Body = z.object({ phone: z.string().min(8).max(15) });

export const POST = handler(async (req: NextRequest) => {
  const { phone } = Body.parse(await req.json());

  const recent = await prisma.otp.findFirst({
    where: { phone, createdAt: { gt: new Date(Date.now() - 45_000) } },
  });
  if (recent) return fail('Please wait before requesting another code', 429);

  const code = generateOtp();
  await prisma.otp.create({
    data: { phone, code, expiresAt: new Date(Date.now() + 10 * 60_000) },
  });

  // In production this is where the SMS gateway call goes. In development we
  // return the code so the app can prefill it.
  if (process.env.NODE_ENV !== 'production') {
    return json({ ok: true, devCode: code });
  }
  return json({ ok: true });
});
