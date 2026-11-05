import { handler, json } from '@/lib/api';
import { prisma } from '@/lib/db';

export const GET = handler(async () => {
  const banners = await prisma.bannerItem.findMany({
    where: { active: true },
    orderBy: { sortOrder: 'asc' },
  });
  return json(
    banners.map((b) => ({ id: b.id, image: b.image, link: b.link })),
  );
});
