'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useState } from 'react';
import {
  BadgeIndianRupee,
  Banknote,
  BarChart3,
  BookOpen,
  CreditCard,
  Gift,
  Images,
  LayoutDashboard,
  ListChecks,
  LogOut,
  Megaphone,
  Menu,
  Package,
  Settings,
  ShoppingCart,
  Smartphone,
  Users,
  X,
} from 'lucide-react';

import { EpayWordmarkDark } from './Logo';

const NAV = [
  { group: 'Overview', items: [{ href: '/admin', label: 'Dashboard', icon: LayoutDashboard }] },
  {
    group: 'Operations',
    items: [
      { href: '/admin/users', label: 'Users', icon: Users },
      { href: '/admin/orders', label: 'Orders', icon: ShoppingCart },
      { href: '/admin/recharges', label: 'Recharges', icon: BadgeIndianRupee },
      { href: '/admin/withdrawals', label: 'Withdrawals', icon: Banknote },
    ],
  },
  {
    group: 'Catalogue',
    items: [
      { href: '/admin/products', label: 'Products', icon: Package },
      { href: '/admin/vip', label: 'VIP Tiers', icon: CreditCard },
      { href: '/admin/banners', label: 'Banners', icon: Images },
    ],
  },
  {
    group: 'Engagement',
    items: [
      { href: '/admin/notices', label: 'Notices', icon: Megaphone },
      { href: '/admin/blogs', label: 'Blog Review', icon: BookOpen },
      { href: '/admin/tasks', label: 'Tasks', icon: ListChecks },
      { href: '/admin/lucky', label: 'Lucky Wheel', icon: Gift },
    ],
  },
  {
    group: 'System',
    items: [
      { href: '/admin/app', label: 'Mobile App', icon: Smartphone },
      { href: '/admin/reports', label: 'Reports', icon: BarChart3 },
      { href: '/admin/settings', label: 'Settings', icon: Settings },
    ],
  },
];

export function Sidebar({ adminName }: { adminName: string }) {
  const pathname = usePathname();
  const router = useRouter();
  const [open, setOpen] = useState(false);

  const logout = async () => {
    await fetch('/api/admin/logout', { method: 'POST' });
    router.replace('/admin/login');
    router.refresh();
  };

  const nav = (
    <nav className="flex h-full flex-col">
      <div className="px-5 py-5">
        <EpayWordmarkDark size={32} />
        <p className="mt-1.5 text-[11px] font-medium uppercase tracking-widest text-slate-400">
          Admin Console
        </p>
      </div>

      <div className="flex-1 space-y-5 overflow-y-auto px-3 pb-4">
        {NAV.map((section) => (
          <div key={section.group}>
            <p className="px-3 pb-1.5 text-[10px] font-bold uppercase tracking-widest text-slate-500">
              {section.group}
            </p>
            <ul className="space-y-0.5">
              {section.items.map((item) => {
                const active =
                  item.href === '/admin'
                    ? pathname === '/admin'
                    : pathname.startsWith(item.href);
                const Icon = item.icon;
                return (
                  <li key={item.href}>
                    <Link
                      href={item.href}
                      onClick={() => setOpen(false)}
                      className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition ${
                        active
                          ? 'bg-gradient-to-r from-blue-600 to-blue-700 text-white shadow-sm'
                          : 'text-slate-300 hover:bg-white/5 hover:text-white'
                      }`}
                    >
                      <Icon size={17} />
                      {item.label}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </div>

      <div className="border-t border-white/10 px-4 py-4">
        <p className="truncate text-xs text-slate-400">Signed in as</p>
        <p className="truncate text-sm font-semibold text-white">{adminName}</p>
        <button
          onClick={logout}
          className="mt-3 flex w-full items-center justify-center gap-2 rounded-lg border border-white/15 px-3 py-2 text-sm font-semibold text-slate-200 transition hover:bg-white/10"
        >
          <LogOut size={15} />
          Log out
        </button>
      </div>
    </nav>
  );

  return (
    <>
      {/* mobile top bar */}
      <div className="sticky top-0 z-30 flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3 lg:hidden">
        <EpayWordmarkDark size={28} />
        <button
          onClick={() => setOpen(true)}
          className="rounded-lg border border-slate-300 p-2 text-slate-700"
          aria-label="Open menu"
        >
          <Menu size={18} />
        </button>
      </div>

      {/* desktop rail */}
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-60 bg-slate-900 lg:block">
        {nav}
      </aside>

      {/* mobile drawer */}
      {open && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <button
            className="absolute inset-0 bg-slate-900/60"
            onClick={() => setOpen(false)}
            aria-label="Close menu"
          />
          <div className="absolute inset-y-0 left-0 w-64 bg-slate-900">
            <button
              onClick={() => setOpen(false)}
              className="absolute right-3 top-4 rounded-lg p-1.5 text-slate-300 hover:bg-white/10"
              aria-label="Close menu"
            >
              <X size={18} />
            </button>
            {nav}
          </div>
        </div>
      )}
    </>
  );
}
