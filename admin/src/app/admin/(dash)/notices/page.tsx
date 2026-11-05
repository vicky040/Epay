import {
  Badge,
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
  Textarea,
  when,
} from '@/components/ui';
import { prisma } from '@/lib/db';
import { deleteNotice, saveNotice } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function NoticesPage({
  searchParams,
}: {
  searchParams: Promise<{ edit?: string }>;
}) {
  const { edit } = await searchParams;

  const [notices, editing] = await Promise.all([
    prisma.notice.findMany({
      orderBy: [{ pinned: 'desc' }, { createdAt: 'desc' }],
    }),
    edit ? prisma.notice.findUnique({ where: { id: edit } }) : null,
  ]);

  const n = editing;

  return (
    <>
      <PageTitle
        title="Notices"
        subtitle="Announcements shown on the app's Notice tab"
      />

      <div className="grid gap-5 xl:grid-cols-5">
        <Card className="xl:col-span-2">
          <CardHeader title={n ? 'Edit notice' : 'New notice'} />
          <form action={saveNotice} className="space-y-4 p-5">
            <input type="hidden" name="id" value={n?.id ?? ''} />

            <Field label="Title">
              <Input name="title" defaultValue={n?.title ?? ''} required />
            </Field>

            <Field label="Thumbnail URL" hint="Optional — a tinted icon is used if empty">
              <Input name="image" defaultValue={n?.image ?? ''} />
            </Field>

            <Field label="Body">
              <Textarea
                name="body"
                rows={12}
                defaultValue={n?.body ?? ''}
                placeholder={'1: First rule\n\n2: Second rule'}
              />
            </Field>

            <div className="flex items-center gap-5">
              <label className="flex items-center gap-2 text-sm text-slate-700">
                <input
                  type="checkbox"
                  name="pinned"
                  defaultChecked={n?.pinned ?? false}
                  className="h-4 w-4 rounded border-slate-300"
                />
                Pin to top
              </label>
              <label className="flex items-center gap-2 text-sm text-slate-700">
                <input
                  type="checkbox"
                  name="published"
                  defaultChecked={n?.published ?? true}
                  className="h-4 w-4 rounded border-slate-300"
                />
                Published
              </label>
            </div>

            <div className="flex gap-2 pt-1">
              <Button type="submit">{n ? 'Save changes' : 'Publish notice'}</Button>
              {n && (
                <a
                  href="/admin/notices"
                  className="inline-flex items-center rounded-lg border border-slate-300 px-3.5 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
                >
                  Cancel
                </a>
              )}
            </div>
          </form>
        </Card>

        <Card className="xl:col-span-3">
          <CardHeader title="All notices" subtitle={`${notices.length} total`} />
          <Table>
            <thead>
              <tr>
                <Th>Title</Th>
                <Th>Status</Th>
                <Th>Created</Th>
                <Th className="text-right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {notices.length === 0 && (
                <EmptyRow colSpan={4} label="No notices yet" />
              )}
              {notices.map((item) => (
                <tr key={item.id} className="hover:bg-slate-50">
                  <Td>
                    <div className="font-semibold text-slate-900">{item.title}</div>
                    <div className="mt-0.5 line-clamp-1 max-w-sm text-xs text-slate-500">
                      {item.body}
                    </div>
                  </Td>
                  <Td>
                    <div className="flex gap-1.5">
                      <Badge tone={item.published ? 'green' : 'slate'}>
                        {item.published ? 'Live' : 'Draft'}
                      </Badge>
                      {item.pinned && <Badge tone="amber">Pinned</Badge>}
                    </div>
                  </Td>
                  <Td className="text-xs text-slate-500">{when(item.createdAt)}</Td>
                  <Td className="text-right">
                    <div className="flex justify-end gap-2">
                      <a
                        href={`/admin/notices?edit=${item.id}`}
                        className="rounded-lg border border-slate-300 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                      >
                        Edit
                      </a>
                      <form action={deleteNotice}>
                        <input type="hidden" name="id" value={item.id} />
                        <button className="rounded-lg border border-red-200 px-2.5 py-1 text-xs font-semibold text-red-600 hover:bg-red-50">
                          Delete
                        </button>
                      </form>
                    </div>
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
