import {
  Button,
  Card,
  CardHeader,
  EmptyRow,
  Field,
  Input,
  PageTitle,
  Table,
  Td,
  Th,
  inr,
  inputClass,
} from '@/components/ui';
import { prisma } from '@/lib/db';
import { deleteVipTier, saveVipTier } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function VipPage() {
  const [tiers, counts] = await Promise.all([
    prisma.vipTier.findMany({ orderBy: { level: 'asc' } }),
    prisma.user.groupBy({
      by: ['vipLevel'],
      _count: { _all: true },
      where: { isAdmin: false },
    }),
  ]);

  const memberCount = (level: number) =>
    counts.find((c) => c.vipLevel === level)?._count._all ?? 0;

  const nextLevel = tiers.length ? Math.max(...tiers.map((t) => t.level)) + 1 : 0;

  return (
    <>
      <PageTitle
        title="VIP tiers"
        subtitle="Thresholds are measured against a user's lifetime invested total"
      />

      <div className="grid gap-5 xl:grid-cols-4">
        <Card className="xl:col-span-1">
          <CardHeader title="Add tier" />
          <form action={saveVipTier} className="space-y-4 p-5">
            <Field label="Level">
              <Input name="level" type="number" min={0} defaultValue={nextLevel} required />
            </Field>
            <Field label="Investment required (₹)">
              <Input name="requiredAmount" type="number" step="0.01" required />
            </Field>
            <Field label="Daily check-in bonus (₹)">
              <Input name="dailyBonus" type="number" step="0.01" defaultValue={0} />
            </Field>
            <Field label="Perks">
              <Input name="perks" placeholder="What this tier unlocks" />
            </Field>
            <Button type="submit">Save tier</Button>
          </form>
        </Card>

        <Card className="xl:col-span-3">
          <CardHeader title="Tiers" subtitle={`${tiers.length} configured`} />
          <Table>
            <thead>
              <tr>
                <Th>Level</Th>
                <Th>Required</Th>
                <Th>Daily bonus</Th>
                <Th>Perks</Th>
                <Th>Members</Th>
                <Th className="text-right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {tiers.length === 0 && <EmptyRow colSpan={6} label="No tiers yet" />}
              {tiers.map((t) => (
                <tr key={t.level}>
                  <Td>
                    <span className="inline-grid h-9 w-11 place-items-center rounded-lg bg-gradient-to-br from-blue-500 to-blue-800 text-xs font-bold text-white">
                      LV{t.level}
                    </span>
                  </Td>
                  <Td>
                    <form action={saveVipTier} className="flex items-center gap-2">
                      <input type="hidden" name="level" value={t.level} />
                      <input
                        name="requiredAmount"
                        type="number"
                        step="0.01"
                        defaultValue={t.requiredAmount}
                        className={`${inputClass} w-28 !py-1.5 text-xs`}
                      />
                      <input
                        name="dailyBonus"
                        type="number"
                        step="0.01"
                        defaultValue={t.dailyBonus}
                        className={`${inputClass} w-24 !py-1.5 text-xs`}
                      />
                      <input
                        name="perks"
                        defaultValue={t.perks}
                        className={`${inputClass} w-56 !py-1.5 text-xs`}
                      />
                      <button className="rounded-lg border border-slate-300 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-50">
                        Save
                      </button>
                    </form>
                  </Td>
                  <Td className="text-emerald-700">{inr(t.dailyBonus)}</Td>
                  <Td className="max-w-[220px] text-xs text-slate-500">{t.perks}</Td>
                  <Td className="font-semibold text-slate-900">
                    {memberCount(t.level)}
                  </Td>
                  <Td className="text-right">
                    {t.level !== 0 && (
                      <form action={deleteVipTier}>
                        <input type="hidden" name="level" value={t.level} />
                        <button className="rounded-lg border border-red-200 px-2.5 py-1 text-xs font-semibold text-red-600 hover:bg-red-50">
                          Delete
                        </button>
                      </form>
                    )}
                  </Td>
                </tr>
              ))}
            </tbody>
          </Table>
          <p className="border-t border-slate-100 px-5 py-3 text-xs text-slate-500">
            The inline row edits Required / Daily bonus / Perks together — the
            columns to the right show the saved values.
          </p>
        </Card>
      </div>
    </>
  );
}
