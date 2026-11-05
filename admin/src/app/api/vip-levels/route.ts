import { handler, json } from '@/lib/api';
import { prisma } from '@/lib/db';

export const GET = handler(async () => {
  const tiers = await prisma.vipTier.findMany({ orderBy: { level: 'asc' } });
  return json(
    tiers.map((t) => ({
      level: t.level,
      requiredAmount: t.requiredAmount,
      dailyBonus: t.dailyBonus,
      perks: t.perks,
    })),
  );
});
