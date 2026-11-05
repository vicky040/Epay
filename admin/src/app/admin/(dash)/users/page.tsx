import Link from 'next/link';
import { Search } from 'lucide-react';

import {
  Badge,
  Card,
  EmptyRow,
  PageTitle,
  Table,
  Td,
  Th,
  inr,
  inputClass,
  when,
} from '@/components/ui';
import { prisma } from '@/lib/db';

export const dynamic = 'force-dynamic';

const PAGE_SIZE = 25;

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; page?: string; status?: string }>;
}) {
  const sp = await searchParams;
  const q = (sp.q ?? '').trim();
  const status = sp.status ?? 'all';
  const page = Math.max(1, Number(sp.page ?? 1) || 1);

  const where = {
    isAdmin: false,
    ...(status === 'all' ? {} : { status }),
    ...(q
      ? {
          OR: [
            { phone: { contains: q } },
            { nickname: { contains: q } },
            { inviteCode: { contains: q.toUpperCase() } },
          ],
        }
      : {}),
  };

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * PAGE_SIZE,
      take: PAGE_SIZE,
      include: { _count: { select: { referrals: true, orders: true } } },
    }),
    prisma.user.count({ where }),
  ]);

  const pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const link = (p: number) =>
    `/admin/users?page=${p}${q ? `&q=${encodeURIComponent(q)}` : ''}${
      status !== 'all' ? `&status=${status}` : ''
    }`;

  return (
    <>
      <PageTitle
        title="Users"
        subtitle={`${total.toLocaleString('en-IN')} registered member${total === 1 ? '' : 's'}`}
      />

      <Card className="mb-5 p-4">
        <form className="flex flex-wrap items-end gap-3" action="/admin/users">
          <div className="min-w-[220px] flex-1">
            <span className="mb-1.5 block text-xs font-semibold text-slate-700">
              Search
            </span>
            <div className="relative">
              <Search
                size={15}
                className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
              />
              <input
                name="q"
                defaultValue={q}
                placeholder="Phone, nickname or invite code"
                className={`${inputClass} pl-9`}
              />
            </div>
          </div>
          <div className="w-40">
            <span className="mb-1.5 block text-xs font-semibold text-slate-700">
              Status
            </span>
            <select name="status" defaultValue={status} className={inputClass}>
              <option value="all">All</option>
              <option value="active">Active</option>
              <option value="frozen">Frozen</option>
            </select>
          </div>
          <button className="rounded-lg bg-gradient-to-r from-blue-600 to-blue-800 px-4 py-2 text-sm font-semibold text-white">
            Filter
          </button>
        </form>
      </Card>

      <Card>
        <Table>
          <thead>
            <tr>
              <Th>User</Th>
              <Th>VIP</Th>
              <Th>Recharge</Th>
              <Th>Withdrawable</Th>
              <Th>Invested</Th>
              <Th>Team</Th>
              <Th>Status</Th>
              <Th className="text-right">Joined</Th>
            </tr>
          </thead>
          <tbody>
            {users.length === 0 && <EmptyRow colSpan={8} label="No users found" />}
            {users.map((u) => (
              <tr key={u.id} className="hover:bg-slate-50">
                <Td>
                  <Link
                    href={`/admin/users/${u.id}`}
                    className="font-semibold text-slate-900 hover:text-blue-600"
                  >
                    {u.nickname}
                  </Link>
                  <div className="text-xs text-slate-500">
                    {u.phone} · {u.inviteCode}
                  </div>
                </Td>
                <Td>
                  <Badge tone="blue">VIP {u.vipLevel}</Badge>
                </Td>
                <Td>{inr(u.rechargeBalance)}</Td>
                <Td className="font-medium text-emerald-700">
                  {inr(u.withdrawBalance)}
                </Td>
                <Td>{inr(u.totalInvested)}</Td>
                <Td>{u._count.referrals}</Td>
                <Td>
                  <Badge tone={u.status === 'active' ? 'green' : 'red'}>
                    {u.status}
                  </Badge>
                </Td>
                <Td className="text-right text-xs text-slate-500">
                  {when(u.createdAt)}
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>

        {pages > 1 && (
          <div className="flex items-center justify-between border-t border-slate-100 px-5 py-3">
            <p className="text-xs text-slate-500">
              Page {page} of {pages}
            </p>
            <div className="flex gap-2">
              {page > 1 && (
                <Link
                  href={link(page - 1)}
                  className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                >
                  Previous
                </Link>
              )}
              {page < pages && (
                <Link
                  href={link(page + 1)}
                  className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                >
                  Next
                </Link>
              )}
            </div>
          </div>
        )}
      </Card>
    </>
  );
}
