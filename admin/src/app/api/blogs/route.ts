import { NextRequest } from 'next/server';
import { z } from 'zod';

import { handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { bumpTask } from '@/lib/earnings';
import { publicBlog } from '@/lib/serialize';

export const GET = handler(async () => {
  const blogs = await prisma.blog.findMany({
    where: { status: 'approved' },
    orderBy: { createdAt: 'desc' },
    take: 100,
    include: { user: { select: { phone: true } } },
  });
  return json(blogs.map(publicBlog));
});

const Body = z.object({
  content: z.string().min(5).max(1000),
  photos: z.array(z.string().max(500)).max(9).default([]),
});

export const POST = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const { content, photos } = Body.parse(await req.json());

  await prisma.blog.create({
    data: { userId: user.id, content, photos: JSON.stringify(photos) },
  });
  await bumpTask(user.id, 'post_blog');

  return json({
    ok: true,
    message: 'Submitted for review. Your reward arrives once approved.',
  });
});
