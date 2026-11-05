import { clearAdminCookie } from '@/lib/auth';
import { handler, json } from '@/lib/api';

export const POST = handler(async () => {
  await clearAdminCookie();
  return json({ ok: true });
});
