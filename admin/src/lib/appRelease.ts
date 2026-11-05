import { getSettings } from './earnings';

export type AppRelease = {
  apkUrl: string;
  version: string;
  sizeBytes: number;
  notes: string;
  updatedAt: string;
  iosUrl: string;
  webUrl: string;
};

export const RELEASE_KEYS = [
  'appApkUrl',
  'appApkVersion',
  'appApkSize',
  'appApkNotes',
  'appApkUpdatedAt',
  'appIosUrl',
  'appWebUrl',
] as const;

export async function getAppRelease(): Promise<AppRelease> {
  const s = await getSettings();
  return {
    apkUrl: s.appApkUrl ?? '',
    version: s.appApkVersion ?? '',
    sizeBytes: Number(s.appApkSize ?? 0),
    notes: s.appApkNotes ?? '',
    updatedAt: s.appApkUpdatedAt ?? '',
    iosUrl: s.appIosUrl ?? '',
    webUrl: s.appWebUrl ?? '',
  };
}

export function formatBytes(bytes: number) {
  if (!bytes) return '—';
  const mb = bytes / (1024 * 1024);
  if (mb >= 1) return `${mb.toFixed(1)} MB`;
  return `${(bytes / 1024).toFixed(0)} KB`;
}
