import { NextRequest } from 'next/server';
import { z } from 'zod';

import { handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { accrueEarnings, syncVipLevel } from '@/lib/earnings';
import { publicUser } from '@/lib/serialize';

export const GET = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  await accrueEarnings(user.id);
  await syncVipLevel(user.id);

  const fresh = await prisma.user.findUnique({ where: { id: user.id } });
  return json(publicUser(fresh!));
});

const Patch = z.object({
  nickname: z.string().min(1).max(24).nullish(),
  avatar: z.string().max(500).nullish(),
});

export const PATCH = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const body = Patch.parse(await req.json());
  const updated = await prisma.user.update({
    where: { id: user.id },
    data: {
      ...(body.nickname ? { nickname: body.nickname } : {}),
      ...(body.avatar !== undefined ? { avatar: body.avatar } : {}),
    },
  });

  return json(publicUser(updated));
});
