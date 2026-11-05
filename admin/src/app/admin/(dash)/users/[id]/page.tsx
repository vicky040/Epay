import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ChevronLeft } from 'lucide-react';

import {
  Badge,
  Button,
  Card,
  CardHeader,
  EmptyRow,
  Field,
  Input,
  PageTitle,
  Select,
  StatCard,
  Table,
  Td,
  Th,
  inr,
  when,
} from '@/components/ui';
import { prisma } from '@/lib/db';
import {
  adjustBalance,
  grantDraws,
  resetUserPassword,
  setUserStatus,
  setUserVip,
} from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function UserDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const user = await prisma.user.findUnique({
    where: { id },
    include: {
      bankCard: true,
      referredBy: { select: { id: true, nickname: true, phone: true } },
      _count: { select: { referrals: true, orders: true } },
    },
  });
  if (!user) notFound();

  const [orders, txns, tiers] = await Promise.all([
    prisma.order.findMany({
      where: { userId: id },
      orderBy: { createdAt: 'desc' },
      take: 10,
    }),
    prisma.transaction.findMany({
      where: { userId: id },
      orderBy: { createdAt: 'desc' },
      take: 15,
    }),
    prisma.vipTier.findMany({ orderBy: { level: 'asc' } }),
  ]);

  return (
    <>
      <Link
        href="/admin/users"
        className="mb-4 inline-flex items-center gap-1 text-sm font-medium text-slate-500 hover:text-blue-600"
      >
        <ChevronLeft size={16} /> Back to users
      </Link>

      <PageTitle
        title={user.nickname}
        subtitle={`${user.phone} · Invite code ${user.inviteCode} · Joined ${when(user.createdAt)}`}
        action={
          <Badge tone={user.status === 'active' ? 'green' : 'red'}>
            {user.status}
          </Badge>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Recharge balance" value={inr(user.rechargeBalance)} tone="amber" />
        <StatCard label="Withdrawable" value={inr(user.withdrawBalance)} tone="green" />
        <StatCard label="Total invested" value={inr(user.totalInvested)} tone="violet" />
        <StatCard
          label="Product income"
          value={inr(user.productIncome)}
          sub={`${user._count.orders} orders · ${user._count.referrals} referrals`}
          tone="blue"
        />
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader
            title="Adjust balance"
            subtitle="Use a negative amount to deduct"
          />
          <form action={adjustBalance} className="space-y-4 p-5">
            <input type="hidden" name="userId" value={user.id} />
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Wallet">
                <Select name="field" defaultValue="rechargeBalance">
                  <option value="rechargeBalance">Recharge balance</option>
                  <option value="withdrawBalance">Withdrawable balance</option>
                </Select>
              </Field>
              <Field label="Amount (₹)">
                <Input name="amount" type="number" step="0.01" placeholder="500" required />
              </Field>
            </div>
            <Field label="Note">
              <Input name="note" placeholder="Reason for the adjustment" />
            </Field>
            <Button type="submit">Apply adjustment</Button>
          </form>
        </Card>

        <Card>
          <CardHeader title="Account controls" />
          <div className="space-y-5 p-5">
            <form action={setUserVip} className="flex items-end gap-3">
              <input type="hidden" name="userId" value={user.id} />
              <Field label="VIP level" className="flex-1">
                <Select name="vipLevel" defaultValue={String(user.vipLevel)}>
                  {tiers.map((t) => (
                    <option key={t.level} value={t.level}>
                      VIP {t.level} — requires {inr(t.requiredAmount)}
                    </option>
                  ))}
                </Select>
              </Field>
              <Button type="submit" variant="ghost">
                Set
              </Button>
            </form>

            <form action={grantDraws} className="flex items-end gap-3">
              <input type="hidden" name="userId" value={user.id} />
              <Field label="Grant lucky draws" className="flex-1">
                <Input
                  name="draws"
                  type="number"
                  defaultValue={1}
                  min={1}
                  max={99}
                />
              </Field>
              <Button type="submit" variant="ghost">
                Grant
              </Button>
            </form>

            <form action={resetUserPassword} className="flex items-end gap-3">
              <input type="hidden" name="userId" value={user.id} />
              <Field label="Reset password" className="flex-1">
                <Input
                  name="password"
                  placeholder="New password (min 6 chars)"
                  minLength={6}
                  required
                />
              </Field>
              <Button type="submit" variant="ghost">
                Reset
              </Button>
            </form>

            <form action={setUserStatus} className="flex items-center gap-3 border-t border-slate-100 pt-4">
              <input type="hidden" name="userId" value={user.id} />
              <input
                type="hidden"
                name="status"
                value={user.status === 'active' ? 'frozen' : 'active'}
              />
              <Button
                type="submit"
                variant={user.status === 'active' ? 'danger' : 'success'}
              >
                {user.status === 'active' ? 'Freeze account' : 'Unfreeze account'}
              </Button>
              <p className="text-xs text-slate-500">
                A frozen account cannot sign in or transact.
              </p>
            </form>
          </div>
        </Card>
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader title="Bank details" />
          {user.bankCard ? (
            <dl className="divide-y divide-slate-50">
              {[
                ['Holder', user.bankCard.holder],
                ['Account number', user.bankCard.accountNumber],
                ['IFSC', user.bankCard.ifsc],
                ['Bank', user.bankCard.bankName],
                ['UPI', user.bankCard.upi ?? '—'],
              ].map(([k, v]) => (
                <div key={k} className="flex justify-between gap-4 px-5 py-3">
                  <dt className="text-sm text-slate-500">{k}</dt>
                  <dd className="text-sm font-semibold text-slate-900">{v}</dd>
                </div>
              ))}
            </dl>
          ) : (
            <p className="px-5 py-10 text-center text-sm text-slate-400">
              No bank account on file
            </p>
          )}
        </Card>

        <Card>
          <CardHeader title="Referral" />
          <div className="space-y-3 px-5 py-5 text-sm">
            <div className="flex justify-between">
              <span className="text-slate-500">Referred by</span>
              <span className="font-semibold text-slate-900">
                {user.referredBy ? (
                  <Link
                    href={`/admin/users/${user.referredBy.id}`}
                    className="hover:text-blue-600"
                  >
                    {user.referredBy.nickname} ({user.referredBy.phone})
                  </Link>
                ) : (
                  '—'
                )}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Direct referrals</span>
              <span className="font-semibold text-slate-900">
                {user._count.referrals}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Lucky draws left</span>
              <span className="font-semibold text-slate-900">
                {user.drawChances}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Last check-in</span>
              <span className="font-semibold text-slate-900">
                {when(user.lastCheckIn)}
              </span>
            </div>
          </div>
        </Card>
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader title="Recent orders" />
          <Table>
            <thead>
              <tr>
                <Th>Product</Th>
                <Th>Amount</Th>
                <Th>Earned</Th>
                <Th>Status</Th>
              </tr>
            </thead>
            <tbody>
              {orders.length === 0 && <EmptyRow colSpan={4} label="No orders" />}
              {orders.map((o) => (
                <tr key={o.id}>
                  <Td className="font-medium text-slate-900">{o.productTitle}</Td>
                  <Td>{inr(o.amount)}</Td>
                  <Td className="text-emerald-700">{inr(o.earnedSoFar)}</Td>
                  <Td>
                    <Badge tone={o.status === 'active' ? 'blue' : 'slate'}>
                      {o.status}
                    </Badge>
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card>

        <Card>
          <CardHeader title="Recent transactions" />
          <Table>
            <thead>
              <tr>
                <Th>Type</Th>
                <Th>Amount</Th>
                <Th>Status</Th>
                <Th className="text-right">When</Th>
              </tr>
            </thead>
            <tbody>
              {txns.length === 0 && <EmptyRow colSpan={4} label="No transactions" />}
              {txns.map((t) => (
                <tr key={t.id}>
                  <Td className="capitalize">{t.type}</Td>
                  <Td className="font-semibold text-slate-900">{inr(t.amount)}</Td>
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
                  <Td className="text-right text-xs text-slate-500">
                    {when(t.createdAt)}
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
