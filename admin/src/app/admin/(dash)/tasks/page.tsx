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
  inr,
} from '@/components/ui';
import { prisma } from '@/lib/db';
import { deleteTask, saveTask } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

const KNOWN_KEYS = [
  ['first_recharge', 'Credited when a recharge is confirmed'],
  ['first_purchase', 'Credited when the user buys any product'],
  ['invite_friends', 'Increment manually or via referral growth'],
  ['checkin_streak', 'Increments on each daily check-in'],
  ['post_blog', 'Credited when the user publishes a blog post'],
];

export default async function TasksPage({
  searchParams,
}: {
  searchParams: Promise<{ edit?: string }>;
}) {
  const { edit } = await searchParams;

  const [tasks, editing] = await Promise.all([
    prisma.task.findMany({
      orderBy: { sortOrder: 'asc' },
      include: { _count: { select: { progress: true } } },
    }),
    edit ? prisma.task.findUnique({ where: { id: edit } }) : null,
  ]);

  const t = editing;

  return (
    <>
      <PageTitle
        title="Tasks"
        subtitle="Reward missions shown on the app's Tasks screen"
      />

      <div className="grid gap-5 xl:grid-cols-5">
        <Card className="xl:col-span-2">
          <CardHeader title={t ? 'Edit task' : 'New task'} />
          <form action={saveTask} className="space-y-4 p-5">
            <input type="hidden" name="id" value={t?.id ?? ''} />

            <Field
              label="Key"
              hint="The backend increments progress using this key"
            >
              <Input name="key" defaultValue={t?.key ?? ''} required />
            </Field>

            <Field label="Title">
              <Input name="title" defaultValue={t?.title ?? ''} required />
            </Field>

            <Field label="Description">
              <Textarea name="description" rows={2} defaultValue={t?.description ?? ''} />
            </Field>

            <div className="grid grid-cols-2 gap-4">
              <Field label="Reward (₹)">
                <Input
                  name="reward"
                  type="number"
                  step="0.01"
                  defaultValue={t?.reward ?? ''}
                  required
                />
              </Field>
              <Field label="Target count">
                <Input name="target" type="number" min={1} defaultValue={t?.target ?? 1} />
              </Field>
            </div>

            <Field label="Sort order">
              <Input name="sortOrder" type="number" defaultValue={t?.sortOrder ?? 0} />
            </Field>

            <label className="flex items-center gap-2 text-sm text-slate-700">
              <input
                type="checkbox"
                name="active"
                defaultChecked={t?.active ?? true}
                className="h-4 w-4 rounded border-slate-300"
              />
              Active
            </label>

            <div className="flex gap-2">
              <Button type="submit">{t ? 'Save changes' : 'Create task'}</Button>
              {t && (
                <a
                  href="/admin/tasks"
                  className="inline-flex items-center rounded-lg border border-slate-300 px-3.5 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
                >
                  Cancel
                </a>
              )}
            </div>

            <div className="rounded-lg bg-slate-50 p-3">
              <p className="mb-2 text-xs font-bold text-slate-700">
                Keys the backend tracks automatically
              </p>
              <ul className="space-y-1">
                {KNOWN_KEYS.map(([k, d]) => (
                  <li key={k} className="text-[11px] text-slate-500">
                    <code className="font-semibold text-blue-700">{k}</code> — {d}
                  </li>
                ))}
              </ul>
            </div>
          </form>
        </Card>

        <Card className="xl:col-span-3">
          <CardHeader title="All tasks" subtitle={`${tasks.length} configured`} />
          <Table>
            <thead>
              <tr>
                <Th>Task</Th>
                <Th>Reward</Th>
                <Th>Target</Th>
                <Th>Users started</Th>
                <Th>Status</Th>
                <Th className="text-right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {tasks.length === 0 && <EmptyRow colSpan={6} label="No tasks yet" />}
              {tasks.map((item) => (
                <tr key={item.id} className="hover:bg-slate-50">
                  <Td>
                    <div className="font-semibold text-slate-900">{item.title}</div>
                    <code className="text-[11px] text-blue-700">{item.key}</code>
                  </Td>
                  <Td className="font-semibold text-emerald-700">
                    {inr(item.reward)}
                  </Td>
                  <Td>{item.target}</Td>
                  <Td>{item._count.progress}</Td>
                  <Td>
                    <Badge tone={item.active ? 'green' : 'slate'}>
                      {item.active ? 'Active' : 'Off'}
                    </Badge>
                  </Td>
                  <Td className="text-right">
                    <div className="flex justify-end gap-2">
                      <a
                        href={`/admin/tasks?edit=${item.id}`}
                        className="rounded-lg border border-slate-300 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                      >
                        Edit
                      </a>
                      <form action={deleteTask}>
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
