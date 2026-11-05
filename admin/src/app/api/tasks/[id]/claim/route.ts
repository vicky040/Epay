import { NextRequest } from 'next/server';

import { fail, handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

export const POST = handler(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await currentUser(req);
    if (!user) return unauthorized();

    const { id } = await ctx.params;
    const task = await prisma.task.findUnique({ where: { id } });
    if (!task || !task.active) return fail('Task not found', 404);

    const progress = await prisma.taskProgress.findUnique({
      where: { userId_taskId: { userId: user.id, taskId: task.id } },
    });

    if (!progress || progress.progress < task.target) {
      return fail('Task not completed yet', 409);
    }
    if (progress.claimed) return fail('Reward already claimed', 409);

    await prisma.$transaction([
      prisma.taskProgress.update({
        where: { id: progress.id },
        data: { claimed: true },
      }),
      prisma.user.update({
        where: { id: user.id },
        data: { withdrawBalance: { increment: task.reward } },
      }),
      prisma.transaction.create({
        data: {
          userId: user.id,
          type: 'bonus',
          amount: task.reward,
          status: 'success',
          note: task.title,
        },
      }),
    ]);

    return json({ ok: true, reward: task.reward });
  },
);
