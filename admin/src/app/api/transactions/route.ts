import { NextRequest } from 'next/server';

import { handler, json, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { accrueEarnings } from '@/lib/earnings';
import { publicTxn } from '@/lib/serialize';

export const GET = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  await accrueEarnings(user.id);

  const type = req.nextUrl.searchParams.get('type') ?? 'all';
  const rows = await prisma.transaction.findMany({
    where: { userId: user.id, ...(type === 'all' ? {} : { type }) },
    orderBy: { createdAt: 'desc' },
    take: 200,
  });

  return json(rows.map(publicTxn));
});
