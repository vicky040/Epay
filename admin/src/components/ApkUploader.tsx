'use client';

import { upload } from '@vercel/blob/client';
import { CheckCircle2, Loader2, UploadCloud } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useRef, useState } from 'react';

type Phase = 'idle' | 'uploading' | 'saving' | 'done' | 'error';

export function ApkUploader({ currentVersion }: { currentVersion: string }) {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [version, setVersion] = useState(currentVersion || '1.0.0');
  const [notes, setNotes] = useState('');
  const [phase, setPhase] = useState<Phase>('idle');
  const [progress, setProgress] = useState(0);
  const [message, setMessage] = useState<string | null>(null);

  const busy = phase === 'uploading' || phase === 'saving';

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const file = fileRef.current?.files?.[0];
    if (!file) {
      setPhase('error');
      setMessage('Choose an .apk file first');
      return;
    }

    setPhase('uploading');
    setProgress(0);
    setMessage(null);

    try {
      // Straight to Blob — never through a function (4.5 MB body cap).
      const blob = await upload(`releases/epay-${version}.apk`, file, {
        access: 'public',
        handleUploadUrl: '/api/admin/blob-upload',
        contentType: 'application/vnd.android.package-archive',
        onUploadProgress: ({ percentage }) => setProgress(percentage),
      });

      setPhase('saving');

      const res = await fetch('/api/admin/app-release', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          apkUrl: blob.url,
          version,
          sizeBytes: file.size,
          notes,
        }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error ?? 'Could not save the release');
      }

      setPhase('done');
      setMessage(`Version ${version} published`);
      router.refresh();
    } catch (err) {
      setPhase('error');
      setMessage(err instanceof Error ? err.message : 'Upload failed');
    }
  }

  return (
    <form onSubmit={submit} className="space-y-4 p-5">
      <div>
        <span className="mb-1.5 block text-xs font-semibold text-slate-700">
          APK file
        </span>
        <input
          ref={fileRef}
          type="file"
          accept=".apk,application/vnd.android.package-archive"
          disabled={busy}
          className="w-full cursor-pointer rounded-lg border border-dashed border-slate-300 bg-slate-50 px-3 py-6 text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-blue-600 file:px-3 file:py-1.5 file:text-sm file:font-semibold file:text-white hover:border-blue-400"
        />
        <span className="mt-1 block text-[11px] text-slate-500">
          Built with{' '}
          <code className="text-blue-700">flutter build apk --release</code> —
          uploads straight to Vercel Blob, so large files are fine.
        </span>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <label className="block">
          <span className="mb-1.5 block text-xs font-semibold text-slate-700">
            Version
          </span>
          <input
            value={version}
            onChange={(e) => setVersion(e.target.value)}
            disabled={busy}
            placeholder="1.0.0"
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
          />
        </label>
        <label className="block">
          <span className="mb-1.5 block text-xs font-semibold text-slate-700">
            Release notes
          </span>
          <input
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            disabled={busy}
            placeholder="What changed"
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
          />
        </label>
      </div>

      {phase === 'uploading' && (
        <div>
          <div className="h-2 overflow-hidden rounded-full bg-slate-200">
            <div
              className="h-full rounded-full bg-gradient-to-r from-sky-500 to-blue-700 transition-all"
              style={{ width: `${progress}%` }}
            />
          </div>
          <p className="mt-1.5 text-xs text-slate-500">
            Uploading… {progress.toFixed(0)}%
          </p>
        </div>
      )}

      {message && (
        <p
          className={`rounded-lg px-3 py-2 text-xs font-medium ${
            phase === 'error'
              ? 'bg-red-50 text-red-700'
              : 'bg-emerald-50 text-emerald-700'
          }`}
        >
          {message}
        </p>
      )}

      <button
        type="submit"
        disabled={busy}
        className="inline-flex items-center gap-2 rounded-lg bg-gradient-to-r from-blue-600 to-blue-800 px-4 py-2 text-sm font-semibold text-white transition hover:from-blue-500 hover:to-blue-700 disabled:opacity-60"
      >
        {phase === 'uploading' || phase === 'saving' ? (
          <Loader2 size={15} className="animate-spin" />
        ) : phase === 'done' ? (
          <CheckCircle2 size={15} />
        ) : (
          <UploadCloud size={15} />
        )}
        {phase === 'uploading'
          ? 'Uploading…'
          : phase === 'saving'
            ? 'Saving…'
            : 'Publish release'}
      </button>
    </form>
  );
}
