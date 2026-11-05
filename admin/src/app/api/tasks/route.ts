import { NextRequest } from 'next/server';

import { handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

export const GET = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const tasks = await prisma.task.findMany({
    where: { active: true },
    orderBy: { sortOrder: 'asc' },
    include: { progress: { where: { userId: user.id } } },
  });

  return json(
    tasks.map((t) => {
      const p = t.progress[0];
      return {
        id: t.id,
        title: t.title,
        description: t.description,
        reward: t.reward,
        progress: p?.progress ?? 0,
        target: t.target,
        claimed: p?.claimed ?? false,
      };
    }),
  );
});
