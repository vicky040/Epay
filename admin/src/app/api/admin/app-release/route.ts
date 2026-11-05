import { NextRequest } from 'next/server';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';

import { fail, handler, json } from '@/lib/api';
import { requireAdmin } from '@/lib/auth';
import { setSetting } from '@/lib/earnings';

const Body = z.object({
  apkUrl: z.string().url(),
  version: z.string().min(1).max(32),
  sizeBytes: z.number().int().nonnegative(),
  notes: z.string().max(500).default(''),
});

export const POST = handler(async (req: NextRequest) => {
  const admin = await requireAdmin(req);
  if (!admin) return fail('Not allowed', 403);

  const b = Body.parse(await req.json());

  await Promise.all([
    setSetting('appApkUrl', b.apkUrl),
    setSetting('appApkVersion', b.version),
    setSetting('appApkSize', String(b.sizeBytes)),
    setSetting('appApkNotes', b.notes),
    setSetting('appApkUpdatedAt', new Date().toISOString()),
  ]);

  revalidatePath('/admin/app');
  revalidatePath('/download');

  return json({ ok: true });
});
