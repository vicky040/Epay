import Link from 'next/link';

import { approveTransaction, rejectTransaction } from '@/app/admin/actions';
import {
  Badge,
  Card,
  CardHeader,
  EmptyRow,
  StatCard,
  Table,
  Td,
  Th,
  inr,
  inputClass,
  when,
} from '@/components/ui';
import { prisma } from '@/lib/db';

type Props = {
  type: 'recharge' | 'withdraw';
  title: string;
  subtitle: string;
  approveLabel: string;
  status: string;
};

export async function TxnReview({
  type,
  title,
  subtitle,
  approveLabel,
  status,
}: Props) {
  const where = { type, ...(status === 'all' ? {} : { status }) };

  const [rows, pendingAgg, successAgg, pendingCount] = await Promise.all([
    prisma.transaction.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: {
        user: {
          select: {
            id: true,
            phone: true,
            nickname: true,
            bankCard: true,
          },
        },
      },
    }),
    prisma.transaction.aggregate({
      where: { type, status: 'pending' },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: { type, status: 'success' },
      _sum: { amount: true },
    }),
    prisma.transaction.count({ where: { type, status: 'pending' } }),
  ]);

  const base = type === 'recharge' ? '/admin/recharges' : '/admin/withdrawals';
  const filters = ['pending', 'success', 'rejected', 'all'];

  return (
    <>
      <div className="mb-6">
        <h1 className="text-2xl font-extrabold tracking-tight text-slate-900">
          {title}
        </h1>
        <p className="mt-1 text-sm text-slate-500">{subtitle}</p>
      </div>

      <div className="mb-5 grid gap-4 sm:grid-cols-3">
        <StatCard
          label="Awaiting action"
          value={String(pendingCount)}
          sub={inr(pendingAgg._sum.amount ?? 0)}
          tone="amber"
        />
        <StatCard
          label={type === 'recharge' ? 'Total credited' : 'Total paid out'}
          value={inr(successAgg._sum.amount ?? 0)}
          tone="green"
        />
        <StatCard label="Showing" value={String(rows.length)} tone="blue" />
      </div>

      <div className="mb-4 flex flex-wrap gap-2">
        {filters.map((f) => (
          <Link
            key={f}
            href={`${base}?status=${f}`}
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
        <CardHeader title="Requests" />
        <Table>
          <thead>
            <tr>
              <Th>User</Th>
              <Th>Amount</Th>
              {type === 'withdraw' && <Th>Payout to</Th>}
              {type === 'recharge' && <Th>Method</Th>}
              <Th>Note</Th>
              <Th>Status</Th>
              <Th>Requested</Th>
              <Th className="text-right">Action</Th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && (
              <EmptyRow colSpan={7} label="Nothing to review" />
            )}
            {rows.map((t) => (
              <tr key={t.id} className="hover:bg-slate-50">
                <Td>
                  <Link
                    href={`/admin/users/${t.user.id}`}
                    className="font-semibold text-slate-900 hover:text-blue-600"
                  >
                    {t.user.nickname}
                  </Link>
                  <div className="text-xs text-slate-500">{t.user.phone}</div>
                </Td>
                <Td className="font-bold text-slate-900">{inr(t.amount)}</Td>
                {type === 'withdraw' && (
                  <Td className="text-xs">
                    {t.user.bankCard ? (
                      <>
                        <div className="font-medium text-slate-800">
                          {t.user.bankCard.bankName}
                        </div>
                        <div className="text-slate-500">
                          {t.user.bankCard.accountNumber} · {t.user.bankCard.ifsc}
                        </div>
                        <div className="text-slate-500">
                          {t.user.bankCard.holder}
                        </div>
                      </>
                    ) : (
                      <span className="text-red-500">No bank account</span>
                    )}
                  </Td>
                )}
                {type === 'recharge' && (
                  <Td className="uppercase">{t.method ?? '—'}</Td>
                )}
                <Td className="max-w-[200px] text-xs text-slate-500">
                  {t.note ?? '—'}
                </Td>
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
                <Td className="text-xs text-slate-500">{when(t.createdAt)}</Td>
                <Td className="text-right">
                  {t.status === 'pending' ? (
                    <div className="flex items-center justify-end gap-2">
                      <form action={approveTransaction}>
                        <input type="hidden" name="id" value={t.id} />
                        <button className="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-500">
                          {approveLabel}
                        </button>
                      </form>
                      <form action={rejectTransaction} className="flex gap-1.5">
                        <input type="hidden" name="id" value={t.id} />
                        <input
                          name="reason"
                          placeholder="Reason"
                          className={`${inputClass} w-28 !py-1.5 text-xs`}
                        />
                        <button className="rounded-lg border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50">
                          Reject
                        </button>
                      </form>
                    </div>
                  ) : (
                    <span className="text-xs text-slate-400">
                      {when(t.updatedAt)}
                    </span>
                  )}
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      </Card>
    </>
  );
}
