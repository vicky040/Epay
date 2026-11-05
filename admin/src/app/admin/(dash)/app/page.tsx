import { Download, ExternalLink, Smartphone } from 'lucide-react';
import Link from 'next/link';
import { headers } from 'next/headers';
import QRCode from 'qrcode';

import { ApkUploader } from '@/components/ApkUploader';
import {
  Badge,
  Button,
  Card,
  CardHeader,
  Field,
  Input,
  PageTitle,
  StatCard,
  when,
} from '@/components/ui';
import { formatBytes, getAppRelease } from '@/lib/appRelease';
import { saveAppLinks } from '@/app/admin/actions';

export const dynamic = 'force-dynamic';

export default async function AppReleasePage() {
  const release = await getAppRelease();

  const h = await headers();
  const host = h.get('x-forwarded-host') ?? h.get('host') ?? 'localhost:3000';
  const proto = host.startsWith('localhost') ? 'http' : 'https';
  const downloadPage = `${proto}://${host}/download`;

  const qr = await QRCode.toDataURL(downloadPage, {
    width: 360,
    margin: 1,
    color: { dark: '#0A2A5E', light: '#FFFFFF' },
  });

  const published = Boolean(release.apkUrl);

  return (
    <>
      <PageTitle
        title="Mobile app"
        subtitle="Publish the Android build and share the download link with your users"
        action={
          <Link
            href="/download"
            target="_blank"
            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3.5 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          >
            <ExternalLink size={15} />
            Open public page
          </Link>
        }
      />

      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard
          label="Current version"
          value={release.version || '—'}
          sub={published ? `Updated ${when(release.updatedAt)}` : 'Nothing published yet'}
          tone="blue"
          icon={<Smartphone size={19} />}
        />
        <StatCard
          label="Package size"
          value={formatBytes(release.sizeBytes)}
          tone="violet"
        />
        <StatCard
          label="Status"
          value={published ? 'Live' : 'Not published'}
          sub={published ? 'Users can install it now' : 'Upload an APK to go live'}
          tone={published ? 'green' : 'amber'}
          icon={<Download size={19} />}
        />
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader
            title="Publish a new build"
            subtitle="The file goes straight to Vercel Blob, so size is not a problem"
          />
          <ApkUploader currentVersion={release.version} />
        </Card>

        <Card>
          <CardHeader title="Scan to install" subtitle="Points at the public download page" />
          <div className="flex flex-col items-center gap-4 p-5">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={qr}
              alt="QR code linking to the EPay download page"
              width={180}
              height={180}
              className="rounded-xl border border-slate-200"
            />
            <code className="break-all text-center text-[11px] text-slate-500">
              {downloadPage}
            </code>
            {published && (
              <a
                href={release.apkUrl}
                className="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-gradient-to-r from-blue-600 to-blue-800 px-4 py-2.5 text-sm font-semibold text-white hover:from-blue-500 hover:to-blue-700"
              >
                <Download size={15} />
                Download APK
              </a>
            )}
          </div>
        </Card>
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader
            title="Current release"
            action={published ? <Badge tone="green">Live</Badge> : <Badge tone="amber">None</Badge>}
          />
          {published ? (
            <dl className="divide-y divide-slate-50">
              {[
                ['Version', release.version],
                ['Size', formatBytes(release.sizeBytes)],
                ['Published', when(release.updatedAt)],
                ['Notes', release.notes || '—'],
              ].map(([k, v]) => (
                <div key={k} className="flex justify-between gap-6 px-5 py-3">
                  <dt className="shrink-0 text-sm text-slate-500">{k}</dt>
                  <dd className="text-right text-sm font-semibold text-slate-900">
                    {v}
                  </dd>
                </div>
              ))}
              <div className="px-5 py-3">
                <dt className="mb-1 text-sm text-slate-500">Direct file URL</dt>
                <dd className="break-all text-xs text-blue-700">{release.apkUrl}</dd>
              </div>
            </dl>
          ) : (
            <p className="px-5 py-12 text-center text-sm text-slate-400">
              Upload an APK to publish your first release.
            </p>
          )}
        </Card>

        <Card>
          <CardHeader
            title="Other platforms"
            subtitle="Optional links shown on the public download page"
          />
          <form action={saveAppLinks} className="space-y-4 p-5">
            <Field
              label="iOS / App Store URL"
              hint="Leave blank while the iOS build is unreleased"
            >
              <Input
                name="appIosUrl"
                defaultValue={release.iosUrl}
                placeholder="https://apps.apple.com/..."
              />
            </Field>
            <Field label="Web app URL" hint="If you host the Flutter web build">
              <Input
                name="appWebUrl"
                defaultValue={release.webUrl}
                placeholder="https://app.example.com"
              />
            </Field>
            <Button type="submit">Save links</Button>
          </form>
        </Card>
      </div>

      <Card className="mt-5">
        <CardHeader
          title="How to build the APK"
          subtitle="Run this in the epay/ folder, then upload the file above"
        />
        <pre className="overflow-x-auto px-5 py-4 text-xs leading-relaxed text-slate-700">
{`cd epay
flutter build apk --release \\
  --dart-define=API_BASE_URL=${proto}://${host}/api

# output: build/app/outputs/flutter-apk/app-release.apk`}
        </pre>
      </Card>
    </>
  );
}
