import { handler, json } from '@/lib/api';
import { prisma } from '@/lib/db';
import { publicNotice } from '@/lib/serialize';

export const GET = handler(async () => {
  const notices = await prisma.notice.findMany({
    where: { published: true },
    orderBy: [{ pinned: 'desc' }, { createdAt: 'desc' }],
  });
  return json(notices.map(publicNotice));
});
