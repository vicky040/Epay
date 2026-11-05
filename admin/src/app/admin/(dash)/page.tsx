import Link from 'next/link';
import {
  ArrowUpRight,
  BadgeIndianRupee,
  Banknote,
  ShoppingCart,
  Users,
} from 'lucide-react';

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

export const dynamic = 'force-dynamic';

export default async function DashboardPage() {
  const since = new Date();
  since.setDate(since.getDate() - 7);

  const [
    userCount,
    newUsers,
    orderCount,
    investedAgg,
    rechargeAgg,
    withdrawAgg,
    pendingRecharges,
    pendingWithdrawals,
    pendingBlogs,
    recentUsers,
    recentTxns,
    topProducts,
  ] = await Promise.all([
    prisma.user.count({ where: { isAdmin: false } }),
    prisma.user.count({ where: { isAdmin: false, createdAt: { gte: since } } }),
    prisma.order.count(),
    prisma.order.aggregate({ _sum: { amount: true } }),
    prisma.transaction.aggregate({
      where: { type: 'recharge', status: 'success' },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: { type: 'withdraw', status: 'success' },
      _sum: { amount: true },
    }),
    prisma.transaction.count({ where: { type: 'recharge', status: 'pending' } }),
    prisma.transaction.count({ where: { type: 'withdraw', status: 'pending' } }),
    prisma.blog.count({ where: { status: 'pending' } }),
    prisma.user.findMany({
      where: { isAdmin: false },
      orderBy: { createdAt: 'desc' },
      take: 6,
    }),
    prisma.transaction.findMany({
      orderBy: { createdAt: 'desc' },
      take: 8,
      include: { user: { select: { phone: true, nickname: true } } },
    }),
    prisma.order.groupBy({
      by: ['productTitle'],
      _sum: { amount: true },
      _count: { _all: true },
      orderBy: { _sum: { amount: 'desc' } },
      take: 5,
    }),
  ]);

  const invested = investedAgg._sum.amount ?? 0;
  const recharged = rechargeAgg._sum.amount ?? 0;
  const withdrawn = withdrawAgg._sum.amount ?? 0;

  const queue = [
    { label: 'Recharges awaiting confirmation', count: pendingRecharges, href: '/admin/recharges' },
    { label: 'Withdrawals awaiting payout', count: pendingWithdrawals, href: '/admin/withdrawals' },
    { label: 'Blog posts awaiting review', count: pendingBlogs, href: '/admin/blogs' },
  ];

  return (
    <>
      <PageTitle
        title="Dashboard"
        subtitle="Platform health at a glance"
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Total users"
          value={userCount.toLocaleString('en-IN')}
          sub={`+${newUsers} in the last 7 days`}
          tone="blue"
          icon={<Users size={19} />}
        />
        <StatCard
          label="Total invested"
          value={inr(invested)}
          sub={`${orderCount.toLocaleString('en-IN')} orders placed`}
          tone="violet"
          icon={<ShoppingCart size={19} />}
        />
        <StatCard
          label="Recharged"
          value={inr(recharged)}
          sub="Confirmed deposits"
          tone="amber"
          icon={<BadgeIndianRupee size={19} />}
        />
        <StatCard
          label="Paid out"
          value={inr(withdrawn)}
          sub={`Net ${inr(recharged - withdrawn)}`}
          tone="green"
          icon={<Banknote size={19} />}
        />
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-3">
        <Card className="lg:col-span-1">
          <CardHeader title="Action queue" subtitle="Needs your attention" />
          <ul className="divide-y divide-slate-50">
            {queue.map((q) => (
              <li key={q.href}>
                <Link
                  href={q.href}
                  className="flex items-center justify-between gap-3 px-5 py-4 transition hover:bg-slate-50"
                >
                  <span className="text-sm text-slate-700">{q.label}</span>
                  <span className="flex items-center gap-2">
                    {q.count > 0 ? (
                      <Badge tone="amber">{q.count}</Badge>
                    ) : (
                      <Badge tone="green">Clear</Badge>
                    )}
                    <ArrowUpRight size={15} className="text-slate-400" />
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader title="Top products" subtitle="By volume invested" />
          <Table>
            <thead>
              <tr>
                <Th>Product</Th>
                <Th>Orders</Th>
                <Th className="text-right">Volume</Th>
              </tr>
            </thead>
            <tbody>
              {topProducts.length === 0 && (
                <EmptyRow colSpan={3} label="No orders yet" />
              )}
              {topProducts.map((p) => (
                <tr key={p.productTitle}>
                  <Td className="font-medium text-slate-900">{p.productTitle}</Td>
                  <Td>{p._count._all}</Td>
                  <Td className="text-right font-semibold text-slate-900">
                    {inr(p._sum.amount ?? 0)}
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card>
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader
            title="Newest users"
            action={
              <Link
                href="/admin/users"
                className="text-xs font-semibold text-blue-600 hover:underline"
              >
                View all
              </Link>
            }
          />
          <Table>
            <thead>
              <tr>
                <Th>User</Th>
                <Th>VIP</Th>
                <Th className="text-right">Joined</Th>
              </tr>
            </thead>
            <tbody>
              {recentUsers.length === 0 && (
                <EmptyRow colSpan={3} label="No users yet" />
              )}
              {recentUsers.map((u) => (
                <tr key={u.id}>
                  <Td>
                    <Link
                      href={`/admin/users/${u.id}`}
                      className="font-medium text-slate-900 hover:text-blue-600"
                    >
                      {u.nickname}
                    </Link>
                    <div className="text-xs text-slate-500">{u.phone}</div>
                  </Td>
                  <Td>
                    <Badge tone="blue">VIP {u.vipLevel}</Badge>
                  </Td>
                  <Td className="text-right text-xs text-slate-500">
                    {when(u.createdAt)}
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card>

        <Card>
          <CardHeader title="Latest transactions" />
          <Table>
            <thead>
              <tr>
                <Th>User</Th>
                <Th>Type</Th>
                <Th>Status</Th>
                <Th className="text-right">Amount</Th>
              </tr>
            </thead>
            <tbody>
              {recentTxns.length === 0 && (
                <EmptyRow colSpan={4} label="Nothing yet" />
              )}
              {recentTxns.map((t) => (
                <tr key={t.id}>
                  <Td className="text-xs">{t.user.phone}</Td>
                  <Td className="capitalize">{t.type}</Td>
                  <Td>
                    <Badge
                      tone={
                        t.status === 'success'
                          ? 'green'
                          : t.status === 'pending'
                            ? 'amber'
                            : 'red'
                      }
                    >
                      {t.status}
                    </Badge>
                  </Td>
                  <Td className="text-right font-semibold text-slate-900">
                    {inr(t.amount)}
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
