'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Loader2, Lock, Phone } from 'lucide-react';

import { EpayMark } from '@/components/Logo';

export default function AdminLoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await fetch('/api/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, password }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Login failed');
      router.replace('/admin');
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
      setBusy(false);
    }
  }

  return (
    <div className="relative grid min-h-screen place-items-center overflow-hidden bg-slate-900 px-4">
      {/* ambient blue glow */}
      <div className="pointer-events-none absolute -left-32 -top-32 h-96 w-96 rounded-full bg-blue-600/25 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-40 -right-24 h-[28rem] w-[28rem] rounded-full bg-sky-500/20 blur-3xl" />

      <div className="relative w-full max-w-sm">
        <div className="mb-7 flex flex-col items-center">
          <EpayMark size={68} />
          <h1 className="mt-5 text-2xl font-extrabold tracking-tight text-white">
            EPay Admin
          </h1>
          <p className="mt-1.5 text-sm text-slate-400">
            Sign in to manage the platform
          </p>
        </div>

        <form
          onSubmit={submit}
          className="rounded-2xl border border-white/10 bg-white/5 p-6 backdrop-blur"
        >
          <label className="block">
            <span className="mb-1.5 block text-xs font-semibold text-slate-300">
              Phone number
            </span>
            <div className="flex items-center gap-2 rounded-lg border border-white/15 bg-white/5 px-3">
              <Phone size={16} className="shrink-0 text-slate-400" />
              <input
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                autoComplete="username"
                placeholder="9000000000"
                className="w-full bg-transparent py-2.5 text-sm text-white outline-none placeholder:text-slate-500"
              />
            </div>
          </label>

          <label className="mt-4 block">
            <span className="mb-1.5 block text-xs font-semibold text-slate-300">
              Password
            </span>
            <div className="flex items-center gap-2 rounded-lg border border-white/15 bg-white/5 px-3">
              <Lock size={16} className="shrink-0 text-slate-400" />
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                placeholder="••••••••"
                className="w-full bg-transparent py-2.5 text-sm text-white outline-none placeholder:text-slate-500"
              />
            </div>
          </label>

          {error && (
            <p className="mt-4 rounded-lg bg-red-500/15 px-3 py-2 text-xs font-medium text-red-300">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={busy}
            className="mt-6 flex w-full items-center justify-center gap-2 rounded-lg bg-gradient-to-r from-sky-500 to-blue-700 py-2.5 text-sm font-bold text-white shadow-lg shadow-blue-900/40 transition hover:from-sky-400 hover:to-blue-600 disabled:opacity-60"
          >
            {busy && <Loader2 size={15} className="animate-spin" />}
            {busy ? 'Signing in…' : 'Sign in'}
          </button>
        </form>

        <p className="mt-5 text-center text-xs text-slate-500">
          Default seeded login: <span className="font-semibold text-slate-400">9000000000</span>{' '}
          / <span className="font-semibold text-slate-400">admin123</span>
        </p>
      </div>
    </div>
  );
}
