import Image from 'next/image';
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
  inputClass,
  when,
} from '@/components/ui';
import { parseJsonArray } from '@/lib/api';
import { prisma } from '@/lib/db';
import { getSettings } from '@/lib/earnings';
import { reviewBlog } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function BlogsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const sp = await searchParams;
  const status = sp.status ?? 'pending';

  const [blogs, pendingCount, paidAgg, settings] = await Promise.all([
    prisma.blog.findMany({
      where: status === 'all' ? {} : { status },
      orderBy: { createdAt: 'desc' },
      take: 60,
      include: { user: { select: { id: true, phone: true, nickname: true } } },
    }),
    prisma.blog.count({ where: { status: 'pending' } }),
    prisma.blog.aggregate({
      where: { status: 'approved' },
      _sum: { reward: true },
    }),
    getSettings(),
  ]);

  const defaultReward = Number(settings.blogReward ?? 22);

  return (
    <>
      <PageTitle
        title="Blog review"
        subtitle="Approve community posts and set the reward paid to the author"
      />

      <div className="mb-5 grid gap-4 sm:grid-cols-3">
        <StatCard label="Awaiting review" value={String(pendingCount)} tone="amber" />
        <StatCard
          label="Rewards paid"
          value={inr(paidAgg._sum.reward ?? 0)}
          tone="green"
        />
        <StatCard
          label="Default reward"
          value={inr(defaultReward)}
          sub="Change it in Settings"
          tone="blue"
        />
      </div>

      <div className="mb-4 flex flex-wrap gap-2">
        {['pending', 'approved', 'rejected', 'all'].map((f) => (
          <Link
            key={f}
            href={`/admin/blogs?status=${f}`}
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
        <CardHeader title="Posts" subtitle={`${blogs.length} shown`} />
        <Table>
          <thead>
            <tr>
              <Th>Author</Th>
              <Th>Content</Th>
              <Th>Photos</Th>
              <Th>Status</Th>
              <Th>Posted</Th>
              <Th className="text-right">Action</Th>
            </tr>
          </thead>
          <tbody>
            {blogs.length === 0 && <EmptyRow colSpan={6} label="Nothing here" />}
            {blogs.map((b) => {
              const photos = parseJsonArray(b.photos);
              return (
                <tr key={b.id} className="hover:bg-slate-50">
                  <Td>
                    <Link
                      href={`/admin/users/${b.user.id}`}
                      className="font-semibold text-slate-900 hover:text-blue-600"
                    >
                      {b.user.nickname}
                    </Link>
                    <div className="text-xs text-slate-500">{b.user.phone}</div>
                  </Td>
                  <Td className="max-w-sm">
                    <p className="line-clamp-3 text-sm text-slate-700">
                      {b.content}
                    </p>
                  </Td>
                  <Td>
                    <div className="flex gap-1.5">
                      {photos.slice(0, 3).map((p, i) => (
                        <Image
                          key={i}
                          src={p}
                          alt=""
                          width={40}
                          height={40}
                          unoptimized
                          className="h-10 w-10 rounded-md object-cover"
                        />
                      ))}
                      {photos.length === 0 && (
                        <span className="text-xs text-slate-400">None</span>
                      )}
                    </div>
                  </Td>
                  <Td>
                    <Badge
                      tone={
                        b.status === 'approved'
                          ? 'green'
                          : b.status === 'pending'
                            ? 'amber'
                            : 'red'
                      }
                    >
                      {b.status}
                    </Badge>
                    {b.status === 'approved' && b.reward > 0 && (
                      <div className="mt-1 text-xs font-semibold text-emerald-700">
                        {inr(b.reward)}
                      </div>
                    )}
                  </Td>
                  <Td className="text-xs text-slate-500">{when(b.createdAt)}</Td>
                  <Td className="text-right">
                    {b.status === 'pending' ? (
                      <div className="flex items-center justify-end gap-2">
                        <form action={reviewBlog} className="flex gap-1.5">
                          <input type="hidden" name="id" value={b.id} />
                          <input type="hidden" name="decision" value="approved" />
                          <input
                            name="reward"
                            type="number"
                            step="0.01"
                            defaultValue={defaultReward}
                            className={`${inputClass} w-20 !py-1.5 text-xs`}
                          />
                          <button className="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-500">
                            Approve
                          </button>
                        </form>
                        <form action={reviewBlog}>
                          <input type="hidden" name="id" value={b.id} />
                          <input type="hidden" name="decision" value="rejected" />
                          <input type="hidden" name="reward" value="0" />
                          <button className="rounded-lg border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50">
                            Reject
                          </button>
                        </form>
                      </div>
                    ) : (
                      <span className="text-xs text-slate-400">Reviewed</span>
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
