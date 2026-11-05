import { NextRequest } from 'next/server';
import { z } from 'zod';

import { fail, handler, json } from '@/lib/api';
import { signAppToken, verifyPassword } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { accrueEarnings } from '@/lib/earnings';
import { publicUser } from '@/lib/serialize';

const Body = z.object({
  phone: z.string().min(8).max(15),
  password: z.string().min(1).max(64),
});

export const POST = handler(async (req: NextRequest) => {
  const { phone, password } = Body.parse(await req.json());

  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user || !(await verifyPassword(password, user.passwordHash))) {
    return fail('Incorrect phone number or password', 401);
  }
  if (user.status !== 'active') {
    return fail('This account has been frozen. Contact support.', 403);
  }

  await accrueEarnings(user.id);
  const fresh = await prisma.user.findUnique({ where: { id: user.id } });

  return json({
    token: signAppToken(user.id, user.phone),
    user: publicUser(fresh!),
  });
});
