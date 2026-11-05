import {
  Check,
  Download,
  Globe,
  ShieldCheck,
  Smartphone,
  Zap,
} from 'lucide-react';
import type { Metadata } from 'next';
import { headers } from 'next/headers';
import QRCode from 'qrcode';

import { EpayMark } from '@/components/Logo';
import { formatBytes, getAppRelease } from '@/lib/appRelease';

export const dynamic = 'force-dynamic';

export const metadata: Metadata = {
  title: 'Download EPay',
  description: 'Get the EPay app for Android — invest, earn and withdraw.',
};

export default async function DownloadPage() {
  const release = await getAppRelease();

  const h = await headers();
  const host = h.get('x-forwarded-host') ?? h.get('host') ?? 'localhost:3000';
  const proto = host.startsWith('localhost') ? 'http' : 'https';
  const qr = await QRCode.toDataURL(`${proto}://${host}/download`, {
    width: 400,
    margin: 1,
    color: { dark: '#0A2A5E', light: '#FFFFFF' },
  });

  const available = Boolean(release.apkUrl);

  const steps = [
    'Tap “Download for Android”. Your browser may warn about APK files — that is normal for apps installed outside the Play Store.',
    'Open the downloaded file. If Android asks, allow your browser to install unknown apps.',
    'Tap Install, then open EPay and sign up with your phone number.',
  ];

  const features = [
    { icon: Zap, title: 'Daily returns', body: 'Earnings credit automatically every cycle.' },
    { icon: ShieldCheck, title: 'Secure payouts', body: 'Bank-grade encryption on every transaction.' },
    { icon: Smartphone, title: 'Built for mobile', body: 'Fast, native Android build under 60 MB.' },
  ];

  return (
    <main className="relative min-h-screen overflow-hidden bg-slate-900">
      {/* ambient brand glow */}
      <div className="pointer-events-none absolute -left-40 -top-40 h-[32rem] w-[32rem] rounded-full bg-blue-600/25 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-52 -right-32 h-[34rem] w-[34rem] rounded-full bg-sky-500/20 blur-3xl" />

      <div className="relative mx-auto max-w-5xl px-5 py-14 sm:py-20">
        <header className="flex items-center gap-3">
          <EpayMark size={40} />
          <span className="text-xl font-extrabold tracking-tight">
            <span className="text-sky-400">E</span>
            <span className="text-white">Pay</span>
          </span>
        </header>

        <div className="mt-12 grid items-center gap-12 lg:grid-cols-2">
          <div>
            <span className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-3.5 py-1.5 text-xs font-semibold text-sky-300">
              <Smartphone size={13} />
              Android app
            </span>

            <h1 className="mt-5 text-4xl font-extrabold leading-tight tracking-tight text-white sm:text-5xl">
              Invest, earn and
              <br />
              withdraw — from
              <br />
              your phone.
            </h1>

            <p className="mt-5 max-w-md text-base leading-relaxed text-slate-300">
              Download the EPay app to browse investment plans, track daily
              returns, invite your team and withdraw straight to your bank.
            </p>

            <div className="mt-8 flex flex-wrap items-center gap-3">
              {available ? (
                <a
                  href={release.apkUrl}
                  className="inline-flex items-center gap-2.5 rounded-xl bg-gradient-to-r from-sky-500 to-blue-700 px-6 py-3.5 text-base font-bold text-white shadow-lg shadow-blue-900/40 transition hover:from-sky-400 hover:to-blue-600"
                >
                  <Download size={19} />
                  Download for Android
                </a>
              ) : (
                <span className="inline-flex items-center gap-2.5 rounded-xl border border-white/15 bg-white/5 px-6 py-3.5 text-base font-bold text-slate-400">
                  <Download size={19} />
                  Coming soon
                </span>
              )}

              {release.webUrl && (
                <a
                  href={release.webUrl}
                  className="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/5 px-5 py-3.5 text-sm font-semibold text-white transition hover:bg-white/10"
                >
                  <Globe size={17} />
                  Open web app
                </a>
              )}

              {release.iosUrl && (
                <a
                  href={release.iosUrl}
                  className="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/5 px-5 py-3.5 text-sm font-semibold text-white transition hover:bg-white/10"
                >
                  <Smartphone size={17} />
                  Get it on iOS
                </a>
              )}
            </div>

            {available && (
              <p className="mt-4 text-xs text-slate-400">
                Version {release.version} · {formatBytes(release.sizeBytes)} ·
                Android 6.0 and later
                {release.notes && (
                  <>
                    <br />
                    {release.notes}
                  </>
                )}
              </p>
            )}
          </div>

          <div className="flex justify-center lg:justify-end">
            <div className="rounded-3xl border border-white/10 bg-white/5 p-7 backdrop-blur">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={qr}
                alt="QR code to open this download page on a phone"
                width={230}
                height={230}
                className="rounded-2xl"
              />
              <p className="mt-4 text-center text-xs font-medium text-slate-300">
                Scan with your phone camera
              </p>
            </div>
          </div>
        </div>

        <div className="mt-20 grid gap-4 sm:grid-cols-3">
          {features.map((f) => {
            const Icon = f.icon;
            return (
              <div
                key={f.title}
                className="rounded-2xl border border-white/10 bg-white/5 p-5"
              >
                <Icon size={20} className="text-sky-400" />
                <h3 className="mt-3 text-sm font-bold text-white">{f.title}</h3>
                <p className="mt-1.5 text-xs leading-relaxed text-slate-400">
                  {f.body}
                </p>
              </div>
            );
          })}
        </div>

        <section className="mt-16 rounded-2xl border border-white/10 bg-white/5 p-7">
          <h2 className="text-lg font-bold text-white">How to install</h2>
          <ol className="mt-5 space-y-4">
            {steps.map((s, i) => (
              <li key={i} className="flex gap-3.5">
                <span className="grid h-6 w-6 shrink-0 place-items-center rounded-full bg-sky-500/20 text-xs font-bold text-sky-300">
                  {i + 1}
                </span>
                <p className="text-sm leading-relaxed text-slate-300">{s}</p>
              </li>
            ))}
          </ol>
          <div className="mt-6 flex items-start gap-2.5 rounded-xl bg-emerald-500/10 p-4">
            <Check size={16} className="mt-0.5 shrink-0 text-emerald-400" />
            <p className="text-xs leading-relaxed text-emerald-200">
              Only ever install EPay from this page. We never ask for your
              password or OTP over chat, email or phone.
            </p>
          </div>
        </section>

        <footer className="mt-14 border-t border-white/10 pt-7 text-center text-xs text-slate-500">
          © {new Date().getFullYear()} EPay · Smart Investment &amp; Earning
          Platform
        </footer>
      </div>
    </main>
  );
}
