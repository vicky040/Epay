import Image from 'next/image';

import {
  Badge,
  Button,
  Card,
  CardHeader,
  Field,
  Input,
  PageTitle,
} from '@/components/ui';
import { prisma } from '@/lib/db';
import { deleteBanner, saveBanner } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function BannersPage() {
  const banners = await prisma.bannerItem.findMany({
    orderBy: { sortOrder: 'asc' },
  });

  return (
    <>
      <PageTitle
        title="Banners"
        subtitle="The carousel at the top of the app's Home tab"
      />

      <div className="grid gap-5 lg:grid-cols-3">
        <Card className="lg:col-span-1">
          <CardHeader title="Add banner" />
          <form action={saveBanner} className="space-y-4 p-5">
            <Field label="Image URL" hint="Landscape works best (16:9)">
              <Input name="image" placeholder="https://..." required />
            </Field>
            <Field label="Link (optional)">
              <Input name="link" placeholder="https://..." />
            </Field>
            <Field label="Sort order">
              <Input name="sortOrder" type="number" defaultValue={banners.length} />
            </Field>
            <label className="flex items-center gap-2 text-sm text-slate-700">
              <input
                type="checkbox"
                name="active"
                defaultChecked
                className="h-4 w-4 rounded border-slate-300"
              />
              Active
            </label>
            <Button type="submit">Add banner</Button>
          </form>
        </Card>

        <div className="lg:col-span-2">
          {banners.length === 0 ? (
            <Card className="grid place-items-center p-16 text-sm text-slate-400">
              No banners yet
            </Card>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {banners.map((b) => (
                <Card key={b.id} className="overflow-hidden">
                  <div className="relative h-36 w-full bg-slate-100">
                    <Image
                      src={b.image}
                      alt=""
                      fill
                      unoptimized
                      className="object-cover"
                    />
                  </div>
                  <div className="space-y-3 p-4">
                    <div className="flex items-center justify-between">
                      <Badge tone={b.active ? 'green' : 'slate'}>
                        {b.active ? 'Active' : 'Hidden'}
                      </Badge>
                      <span className="text-xs text-slate-500">
                        Order {b.sortOrder}
                      </span>
                    </div>
                    <p className="truncate text-xs text-slate-500">{b.image}</p>
                    <form action={saveBanner} className="space-y-2">
                      <input type="hidden" name="id" value={b.id} />
                      <input type="hidden" name="image" value={b.image} />
                      <input type="hidden" name="link" value={b.link ?? ''} />
                      <div className="flex items-center gap-2">
                        <input
                          name="sortOrder"
                          type="number"
                          defaultValue={b.sortOrder}
                          className="w-20 rounded-lg border border-slate-300 px-2 py-1.5 text-xs"
                        />
                        <label className="flex items-center gap-1.5 text-xs text-slate-700">
                          <input
                            type="checkbox"
                            name="active"
                            defaultChecked={b.active}
                            className="h-3.5 w-3.5 rounded border-slate-300"
                          />
                          Active
                        </label>
                        <button className="ml-auto rounded-lg border border-slate-300 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-50">
                          Save
                        </button>
                      </div>
                    </form>
                    <form action={deleteBanner}>
                      <input type="hidden" name="id" value={b.id} />
                      <button className="w-full rounded-lg border border-red-200 px-2.5 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50">
                        Delete
                      </button>
                    </form>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      </div>
    </>
  );
}
