import {
  Card,
  CardHeader,
  EmptyRow,
  PageTitle,
  StatCard,
  Table,
  Td,
  Th,
  inr,
} from '@/components/ui';
import { prisma } from '@/lib/db';

export const dynamic = 'force-dynamic';

const DAYS = 14;

export default async function ReportsPage() {
  const since = new Date();
  since.setHours(0, 0, 0, 0);
  since.setDate(since.getDate() - (DAYS - 1));

  const [txns, signups, orders, byType, topReferrers] = await Promise.all([
    prisma.transaction.findMany({
      where: { createdAt: { gte: since }, status: 'success' },
      select: { type: true, amount: true, createdAt: true },
    }),
    prisma.user.findMany({
      where: { isAdmin: false, createdAt: { gte: since } },
      select: { createdAt: true },
    }),
    prisma.order.findMany({
      where: { createdAt: { gte: since } },
      select: { amount: true, createdAt: true },
    }),
    prisma.transaction.groupBy({
      by: ['type'],
      where: { status: 'success' },
      _sum: { amount: true },
      _count: { _all: true },
    }),
    prisma.user.findMany({
      where: { isAdmin: false },
      orderBy: { referrals: { _count: 'desc' } },
      take: 8,
      include: { _count: { select: { referrals: true } } },
    }),
  ]);

  // Bucket everything by *local* calendar day. Using toISOString() here would
  // key by UTC and drop rows that fall outside the local range.
  const key = (d: Date) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(
      d.getDate(),
    ).padStart(2, '0')}`;
  const days: { date: string; label: string; signups: number; recharge: number; withdraw: number; invested: number }[] = [];
  for (let i = 0; i < DAYS; i++) {
    const d = new Date(since);
    d.setDate(since.getDate() + i);
    days.push({
      date: key(d),
      label: d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' }),
      signups: 0,
      recharge: 0,
      withdraw: 0,
      invested: 0,
    });
  }
  const index = new Map(days.map((d) => [d.date, d]));

  for (const s of signups) {
    const row = index.get(key(s.createdAt));
    if (row) row.signups++;
  }
  for (const o of orders) {
    const row = index.get(key(o.createdAt));
    if (row) row.invested += o.amount;
  }
  for (const t of txns) {
    const row = index.get(key(t.createdAt));
    if (!row) continue;
    if (t.type === 'recharge') row.recharge += t.amount;
    if (t.type === 'withdraw') row.withdraw += t.amount;
  }

  const peak = Math.max(1, ...days.map((d) => Math.max(d.recharge, d.withdraw)));
  const totals = days.reduce(
    (a, d) => ({
      signups: a.signups + d.signups,
      recharge: a.recharge + d.recharge,
      withdraw: a.withdraw + d.withdraw,
      invested: a.invested + d.invested,
    }),
    { signups: 0, recharge: 0, withdraw: 0, invested: 0 },
  );

  return (
    <>
      <PageTitle
        title="Reports"
        subtitle={`Activity over the last ${DAYS} days`}
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="New users" value={String(totals.signups)} tone="blue" />
        <StatCard label="Recharged" value={inr(totals.recharge)} tone="amber" />
        <StatCard label="Withdrawn" value={inr(totals.withdraw)} tone="green" />
        <StatCard label="Invested" value={inr(totals.invested)} tone="violet" />
      </div>

      <Card className="mt-5">
        <CardHeader
          title="Daily cash flow"
          subtitle="Blue = recharges in, green = withdrawals out"
        />
        <div className="px-5 py-6">
          <div className="flex h-48 items-end gap-2">
            {days.map((d) => (
              <div key={d.date} className="flex flex-1 flex-col items-center gap-1">
                <div className="flex h-40 w-full items-end justify-center gap-1">
                  <div
                    className="w-1/2 rounded-t bg-blue-500"
                    style={{ height: `${(d.recharge / peak) * 100}%` }}
                    title={`Recharged ${inr(d.recharge)}`}
                  />
                  <div
                    className="w-1/2 rounded-t bg-emerald-500"
                    style={{ height: `${(d.withdraw / peak) * 100}%` }}
                    title={`Withdrawn ${inr(d.withdraw)}`}
                  />
                </div>
                <span className="whitespace-nowrap text-[9px] text-slate-500">
                  {d.label}
                </span>
              </div>
            ))}
          </div>
        </div>
      </Card>

      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader title="Lifetime totals by transaction type" />
          <Table>
            <thead>
              <tr>
                <Th>Type</Th>
                <Th>Count</Th>
                <Th className="text-right">Total</Th>
              </tr>
            </thead>
            <tbody>
              {byType.length === 0 && <EmptyRow colSpan={3} label="No data" />}
              {byType.map((t) => (
                <tr key={t.type}>
                  <Td className="font-medium capitalize text-slate-900">{t.type}</Td>
                  <Td>{t._count._all}</Td>
                  <Td className="text-right font-semibold text-slate-900">
                    {inr(t._sum.amount ?? 0)}
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card>

        <Card>
          <CardHeader title="Top referrers" />
          <Table>
            <thead>
              <tr>
                <Th>User</Th>
                <Th>Invite code</Th>
                <Th className="text-right">Referrals</Th>
              </tr>
            </thead>
            <tbody>
              {topReferrers.length === 0 && <EmptyRow colSpan={3} label="No data" />}
              {topReferrers.map((u) => (
                <tr key={u.id}>
                  <Td>
                    <div className="font-medium text-slate-900">{u.nickname}</div>
                    <div className="text-xs text-slate-500">{u.phone}</div>
                  </Td>
                  <Td>
                    <code className="text-xs font-semibold text-blue-700">
                      {u.inviteCode}
                    </code>
                  </Td>
                  <Td className="text-right font-semibold text-slate-900">
                    {u._count.referrals}
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card>
      </div>
    </>
  );
}
