import Image from 'next/image';

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
  Table,
  Td,
  Th,
  Textarea,
  inr,
} from '@/components/ui';
import { prisma } from '@/lib/db';
import { deleteProduct, saveProduct } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function ProductsPage({
  searchParams,
}: {
  searchParams: Promise<{ edit?: string }>;
}) {
  const { edit } = await searchParams;

  const [products, editing] = await Promise.all([
    prisma.product.findMany({ orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }] }),
    edit ? prisma.product.findUnique({ where: { id: edit } }) : null,
  ]);

  const p = editing;

  return (
    <>
      <PageTitle
        title="Products"
        subtitle="Investment plans shown in the app's Invest tab"
      />

      <div className="grid gap-5 xl:grid-cols-3">
        <Card className="xl:col-span-1">
          <CardHeader
            title={p ? 'Edit product' : 'New product'}
            subtitle={p ? p.title : 'Add a plan to the catalogue'}
          />
          <form action={saveProduct} className="space-y-4 p-5">
            <input type="hidden" name="id" value={p?.id ?? ''} />

            <Field label="Title">
              <Input name="title" defaultValue={p?.title ?? ''} required />
            </Field>

            <Field label="Image URL" hint="Shown as the card cover in the app">
              <Textarea name="image" rows={2} defaultValue={p?.image ?? ''} />
            </Field>

            <div className="grid grid-cols-2 gap-4">
              <Field label="Category">
                <Select name="category" defaultValue={p?.category ?? 'steady'}>
                  <option value="steady">Steady</option>
                  <option value="benefits">Benefits</option>
                  <option value="event">Event</option>
                </Select>
              </Field>
              <Field label="VIP required">
                <Input
                  name="vipRequired"
                  type="number"
                  min={0}
                  defaultValue={p?.vipRequired ?? 0}
                />
              </Field>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <Field label="Price (₹)">
                <Input
                  name="price"
                  type="number"
                  step="0.01"
                  defaultValue={p?.price ?? ''}
                  required
                />
              </Field>
              <Field label="Earning per cycle (₹)">
                <Input
                  name="periodEarning"
                  type="number"
                  step="0.01"
                  defaultValue={p?.periodEarning ?? ''}
                  required
                />
              </Field>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <Field label="Duration">
                <Input
                  name="duration"
                  type="number"
                  min={1}
                  defaultValue={p?.duration ?? 1}
                />
              </Field>
              <Field label="Cycle unit">
                <Select name="cycleUnit" defaultValue={p?.cycleUnit ?? 'Days'}>
                  <option value="Days">Days</option>
                  <option value="Hours">Hours</option>
                </Select>
              </Field>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <Field label="Total return (₹)">
                <Input
                  name="total"
                  type="number"
                  step="0.01"
                  defaultValue={p?.total ?? ''}
                  required
                />
              </Field>
              <Field label="Max per user">
                <Input
                  name="maxPerUser"
                  type="number"
                  min={1}
                  defaultValue={p?.maxPerUser ?? 1}
                />
              </Field>
            </div>

            <Field label="Sort order">
              <Input name="sortOrder" type="number" defaultValue={p?.sortOrder ?? 0} />
            </Field>

            <div className="flex items-center gap-5 pt-1">
              <label className="flex items-center gap-2 text-sm text-slate-700">
                <input
                  type="checkbox"
                  name="hot"
                  defaultChecked={p?.hot ?? false}
                  className="h-4 w-4 rounded border-slate-300"
                />
                Mark as hot
              </label>
              <label className="flex items-center gap-2 text-sm text-slate-700">
                <input
                  type="checkbox"
                  name="active"
                  defaultChecked={p?.active ?? true}
                  className="h-4 w-4 rounded border-slate-300"
                />
                Active
              </label>
            </div>

            <div className="flex gap-2 pt-2">
              <Button type="submit">{p ? 'Save changes' : 'Create product'}</Button>
              {p && (
                <a
                  href="/admin/products"
                  className="inline-flex items-center rounded-lg border border-slate-300 px-3.5 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
                >
                  Cancel
                </a>
              )}
            </div>
          </form>
        </Card>

        <Card className="xl:col-span-2">
          <CardHeader
            title="Catalogue"
            subtitle={`${products.length} product${products.length === 1 ? '' : 's'}`}
          />
          <Table>
            <thead>
              <tr>
                <Th>Product</Th>
                <Th>Category</Th>
                <Th>Price</Th>
                <Th>Per cycle</Th>
                <Th>Duration</Th>
                <Th>Total</Th>
                <Th className="text-right">Actions</Th>
              </tr>
            </thead>
            <tbody>
              {products.length === 0 && (
                <EmptyRow colSpan={7} label="No products yet" />
              )}
              {products.map((item) => (
                <tr key={item.id} className="hover:bg-slate-50">
                  <Td>
                    <div className="flex items-center gap-3">
                      {item.image ? (
                        <Image
                          src={item.image}
                          alt=""
                          width={44}
                          height={44}
                          unoptimized
                          className="h-11 w-11 rounded-lg object-cover"
                        />
                      ) : (
                        <div className="h-11 w-11 rounded-lg bg-slate-100" />
                      )}
                      <div>
                        <div className="font-semibold text-slate-900">
                          {item.title}
                        </div>
                        <div className="flex gap-1.5 pt-0.5">
                          <Badge tone="blue">VIP {item.vipRequired}</Badge>
                          {item.hot && <Badge tone="red">Hot</Badge>}
                          {!item.active && <Badge tone="slate">Inactive</Badge>}
                        </div>
                      </div>
                    </div>
                  </Td>
                  <Td className="capitalize">{item.category}</Td>
                  <Td className="font-medium text-amber-700">{inr(item.price)}</Td>
                  <Td className="text-blue-700">{inr(item.periodEarning)}</Td>
                  <Td>
                    {item.duration} {item.cycleUnit}
                  </Td>
                  <Td className="font-semibold text-slate-900">{inr(item.total)}</Td>
                  <Td className="text-right">
                    <div className="flex justify-end gap-2">
                      <a
                        href={`/admin/products?edit=${item.id}`}
                        className="rounded-lg border border-slate-300 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                      >
                        Edit
                      </a>
                      <form action={deleteProduct}>
                        <input type="hidden" name="id" value={item.id} />
                        <button className="rounded-lg border border-red-200 px-2.5 py-1 text-xs font-semibold text-red-600 hover:bg-red-50">
                          Remove
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
