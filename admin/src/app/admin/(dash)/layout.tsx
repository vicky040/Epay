import { redirect } from 'next/navigation';
import type { ReactNode } from 'react';

import { Sidebar } from '@/components/Sidebar';
import { currentAdmin } from '@/lib/auth';

export default async function AdminLayout({ children }: { children: ReactNode }) {
  const admin = await currentAdmin();
  if (!admin) redirect('/admin/login');

  return (
    <div className="min-h-screen bg-slate-50">
      <Sidebar adminName={admin.nickname || admin.phone} />
      <main className="lg:pl-60">
        <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8 lg:py-8">
          {children}
        </div>
      </main>
    </div>
  );
}
