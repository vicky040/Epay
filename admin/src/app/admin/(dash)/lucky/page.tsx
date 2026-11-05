import Link from 'next/link';

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
  inputClass,
  when,
} from '@/components/ui';
import { prisma } from '@/lib/db';
import { saveLuckyPrize } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function LuckyPage() {
  const [prizes, wins, paidAgg, winCount] = await Promise.all([
    prisma.luckyPrize.findMany({ orderBy: { slot: 'asc' } }),
    prisma.luckyWin.findMany({
      orderBy: { createdAt: 'desc' },
      take: 40,
      include: { user: { select: { id: true, phone: true, nickname: true } } },
    }),
    prisma.luckyWin.aggregate({ _sum: { amount: true } }),
    prisma.luckyWin.count(),
  ]);

  const totalWeight = prizes.reduce((s, p) => s + Math.max(p.weight, 0), 0) || 1;

  return (
    <>
      <PageTitle
        title="Lucky wheel"
        subtitle="Prize slots map to the 8 cells around the app's 3×3 grid, clockwise from the top-left"
      />

      <div className="mb-5 grid gap-4 sm:grid-cols-3">
        <StatCard label="Total spins" value={String(winCount)} tone="violet" />
        <StatCard
          label="Prizes paid"
          value={inr(paidAgg._sum.amount ?? 0)}
          tone="amber"
        />
        <StatCard label="Slots configured" value={String(prizes.length)} tone="blue" />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader
            title="Prize slots"
            subtitle="Higher weight = more likely to be drawn"
          />
          <Table>
            <thead>
              <tr>
                <Th>Slot</Th>
                <Th>Amount & weight</Th>
                <Th className="text-right">Odds</Th>
              </tr>
            </thead>
            <tbody>
              {prizes.length === 0 && (
                <EmptyRow colSpan={3} label="No prizes configured" />
              )}
              {prizes.map((p) => (
                <tr key={p.slot}>
                  <Td>
                    <span className="inline-grid h-8 w-8 place-items-center rounded-lg bg-gradient-to-br from-amber-400 to-orange-600 text-xs font-bold text-white">
                      {p.slot}
                    </span>
                  </Td>
                  <Td>
                    <form action={saveLuckyPrize} className="flex items-center gap-2">
                      <input type="hidden" name="slot" value={p.slot} />
                      <input
                        name="amount"
                        type="number"
                        step="0.01"
                        defaultValue={p.amount}
                        className={`${inputClass} w-28 !py-1.5 text-xs`}
                      />
                      <input
                        name="weight"
                        type="number"
                        min={0}
                        defaultValue={p.weight}
                        className={`${inputClass} w-20 !py-1.5 text-xs`}
                      />
                      <button className="rounded-lg border border-slate-300 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-50">
                        Save
                      </button>
                    </form>
                  </Td>
                  <Td className="text-right text-xs font-semibold text-slate-600">
                    {((Math.max(p.weight, 0) / totalWeight) * 100).toFixed(1)}%
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card>

        <Card>
          <CardHeader title="Recent wins" />
          <Table>
            <thead>
              <tr>
                <Th>User</Th>
                <Th>Slot</Th>
                <Th>Amount</Th>
                <Th className="text-right">When</Th>
              </tr>
            </thead>
            <tbody>
              {wins.length === 0 && <EmptyRow colSpan={4} label="No spins yet" />}
              {wins.map((w) => (
                <tr key={w.id}>
                  <Td>
                    <Link
                      href={`/admin/users/${w.user.id}`}
                      className="font-semibold text-slate-900 hover:text-blue-600"
                    >
                      {w.user.nickname}
                    </Link>
                    <div className="text-xs text-slate-500">{w.user.phone}</div>
                  </Td>
                  <Td>{w.slot}</Td>
                  <Td className="font-semibold text-emerald-700">{inr(w.amount)}</Td>
                  <Td className="text-right text-xs text-slate-500">
                    {when(w.createdAt)}
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
