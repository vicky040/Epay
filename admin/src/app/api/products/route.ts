import { NextRequest } from 'next/server';

import { handler, json } from '@/lib/api';
import { prisma } from '@/lib/db';
import { publicProduct } from '@/lib/serialize';

export const GET = handler(async (req: NextRequest) => {
  const category = req.nextUrl.searchParams.get('category') ?? undefined;

  const products = await prisma.product.findMany({
    where: { active: true, ...(category ? { category } : {}) },
    orderBy: [{ sortOrder: 'asc' }, { price: 'asc' }],
  });

  return json(products.map(publicProduct));
});
