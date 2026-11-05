import { NextRequest } from 'next/server';
import { z } from 'zod';

import { fail, handler, json } from '@/lib/api';
import { setAdminCookie, signAdminToken, verifyPassword } from '@/lib/auth';
import { prisma } from '@/lib/db';

const Body = z.object({
  phone: z.string().min(3).max(32),
  password: z.string().min(1).max(64),
});

export const POST = handler(async (req: NextRequest) => {
  const { phone, password } = Body.parse(await req.json());

  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user || !user.isAdmin) return fail('Invalid credentials', 401);
  if (!(await verifyPassword(password, user.passwordHash))) {
    return fail('Invalid credentials', 401);
  }

  await setAdminCookie(signAdminToken(user.id));
  return json({ ok: true });
});
