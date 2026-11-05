import Link from 'next/link';

import {
  Badge,
  Card,
  CardHeader,
  EmptyRow,
  PageTitle,
  StatCard,
  Table,
  Td,
  Th,
  inr,
  when,
} from '@/components/ui';
import { prisma } from '@/lib/db';
import { settleOrder } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function OrdersPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const sp = await searchParams;
  const status = sp.status ?? 'all';
  const where = status === 'all' ? {} : { status };

  const [orders, totalAgg, activeCount, paidAgg] = await Promise.all([
    prisma.order.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: { user: { select: { id: true, phone: true, nickname: true } } },
    }),
    prisma.order.aggregate({ _sum: { amount: true } }),
    prisma.order.count({ where: { status: 'active' } }),
    prisma.order.aggregate({ _sum: { earnedSoFar: true } }),
  ]);

  return (
    <>
      <PageTitle title="Orders" subtitle="Every investment placed in the app" />

      <div className="mb-5 grid gap-4 sm:grid-cols-3">
        <StatCard label="Volume invested" value={inr(totalAgg._sum.amount ?? 0)} tone="violet" />
        <StatCard label="Active orders" value={String(activeCount)} tone="blue" />
        <StatCard
          label="Returns credited"
          value={inr(paidAgg._sum.earnedSoFar ?? 0)}
          tone="green"
        />
      </div>

      <div className="mb-4 flex flex-wrap gap-2">
        {['all', 'active', 'finished'].map((f) => (
          <Link
            key={f}
            href={`/admin/orders?status=${f}`}
            className={`rounded-lg px-3.5 py-1.5 text-sm font-semibold capitalize transition ${
              status === f
                ? 'bg-gradient-to-r from-blue-600 to-blue-800 text-white'
                : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
            }`}
          >
            {f}
          </Link>
        ))}
      </div>

      <Card>
        <CardHeader title="Orders" subtitle={`${orders.length} shown`} />
        <Table>
          <thead>
            <tr>
              <Th>User</Th>
              <Th>Product</Th>
              <Th>Shares</Th>
              <Th>Invested</Th>
              <Th>Earned</Th>
              <Th>Expected</Th>
              <Th>Progress</Th>
              <Th>Status</Th>
              <Th className="text-right">Placed</Th>
            </tr>
          </thead>
          <tbody>
            {orders.length === 0 && <EmptyRow colSpan={9} label="No orders yet" />}
            {orders.map((o) => {
              const pct =
                o.duration > 0
                  ? Math.round((o.cyclesPaid / o.duration) * 100)
                  : 0;
              return (
                <tr key={o.id} className="hover:bg-slate-50">
                  <Td>
                    <Link
                      href={`/admin/users/${o.user.id}`}
                      className="font-semibold text-slate-900 hover:text-blue-600"
                    >
                      {o.user.nickname}
                    </Link>
                    <div className="text-xs text-slate-500">{o.user.phone}</div>
                  </Td>
                  <Td className="font-medium text-slate-900">{o.productTitle}</Td>
                  <Td>{o.shares}</Td>
                  <Td className="text-amber-700">{inr(o.amount)}</Td>
                  <Td className="text-emerald-700">{inr(o.earnedSoFar)}</Td>
                  <Td>{inr(o.expectedTotal)}</Td>
                  <Td>
                    <div className="flex items-center gap-2">
                      <div className="h-1.5 w-16 overflow-hidden rounded-full bg-slate-200">
                        <div
                          className="h-full rounded-full bg-blue-600"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                      <span className="text-xs text-slate-500">{pct}%</span>
                    </div>
                  </Td>
                  <Td>
                    <Badge tone={o.status === 'active' ? 'blue' : 'slate'}>
                      {o.status}
                    </Badge>
                  </Td>
                  <Td className="text-right text-xs text-slate-500">
                    {when(o.createdAt)}
                    {o.status === 'active' && (
                      <form action={settleOrder} className="mt-1">
                        <input type="hidden" name="id" value={o.id} />
                        <button className="rounded border border-slate-300 px-2 py-0.5 text-[11px] font-semibold text-slate-600 hover:bg-slate-50">
                          Close early
                        </button>
                      </form>
                    )}
                  </Td>
                </tr>
              );
            })}
          </tbody>
        </Table>
      </Card>
    </>
  );
}
