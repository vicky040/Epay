import { NextRequest } from 'next/server';
import { z } from 'zod';

import { fail, handler, json, round2, unauthorized } from '@/lib/api';
import { currentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import {
  accrueEarnings,
  bumpTask,
  payReferralRebates,
  syncVipLevel,
} from '@/lib/earnings';
import { publicOrder } from '@/lib/serialize';

export const GET = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  await accrueEarnings(user.id);

  const status = req.nextUrl.searchParams.get('status') ?? 'all';
  const orders = await prisma.order.findMany({
    where: { userId: user.id, ...(status === 'all' ? {} : { status }) },
    orderBy: { createdAt: 'desc' },
  });

  return json(orders.map(publicOrder));
});

const Body = z.object({
  productId: z.string().min(1),
  shares: z.number().int().min(1).max(999).default(1),
});

export const POST = handler(async (req: NextRequest) => {
  const user = await currentUser(req);
  if (!user) return unauthorized();

  const { productId, shares } = Body.parse(await req.json());

  const product = await prisma.product.findUnique({ where: { id: productId } });
  if (!product || !product.active) return fail('Product is not available', 404);
  if (user.vipLevel < product.vipRequired) {
    return fail(`This product requires VIP${product.vipRequired}`, 403);
  }

  const owned = await prisma.order.aggregate({
    where: { userId: user.id, productId },
    _sum: { shares: true },
  });
  if ((owned._sum.shares ?? 0) + shares > product.maxPerUser) {
    return fail(`You can hold at most ${product.maxPerUser} of this product`, 409);
  }

  const cost = round2(product.price * shares);
  if (user.rechargeBalance < cost) {
    return fail('Insufficient balance. Please recharge first.', 402);
  }

  const endsAt = new Date(
    Date.now() +
      product.duration *
        (product.cycleUnit === 'Hours' ? 60 * 60 * 1000 : 24 * 60 * 60 * 1000),
  );

  await prisma.$transaction([
    prisma.user.update({
      where: { id: user.id },
      data: {
        rechargeBalance: { decrement: cost },
        totalInvested: { increment: cost },
        drawChances: { increment: shares },
      },
    }),
    prisma.order.create({
      data: {
        userId: user.id,
        productId: product.id,
        productTitle: product.title,
        productImage: product.image,
        shares,
        amount: cost,
        periodEarning: product.periodEarning,
        cycleUnit: product.cycleUnit,
        duration: product.duration,
        expectedTotal: round2(product.total * shares),
        endsAt,
      },
    }),
    prisma.transaction.create({
      data: {
        userId: user.id,
        type: 'purchase',
        amount: cost,
        status: 'success',
        note: `${product.title} x${shares}`,
      },
    }),
  ]);

  await syncVipLevel(user.id);
  await payReferralRebates(user.id, cost);
  await bumpTask(user.id, 'first_purchase');

  return json({ ok: true, message: 'Investment successful' });
});
