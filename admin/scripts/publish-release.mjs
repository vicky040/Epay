/**
 * Records an already-uploaded APK as the current release.
 *
 * The admin console does this for you (Admin → Mobile App). This script is the
 * CLI equivalent, useful from CI.
 *
 *   node scripts/publish-release.mjs <blobUrl> <version> <pathToApk> ["notes"]
 */
import { statSync } from 'node:fs';

import dotenv from 'dotenv';
import { PrismaNeon } from '@prisma/adapter-neon';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: '.env.local' });
dotenv.config({ path: '.env' });

const [url, version, apkPath, notes = ''] = process.argv.slice(2);

if (!url || !version || !apkPath) {
  console.error(
    'Usage: node scripts/publish-release.mjs <blobUrl> <version> <pathToApk> ["notes"]',
  );
  process.exit(1);
}

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error('DATABASE_URL is not set. Run `vercel env pull .env.local` first.');
  process.exit(1);
}

const prisma = new PrismaClient({ adapter: new PrismaNeon({ connectionString }) });

const size = statSync(apkPath).size;

const values = {
  appApkUrl: url,
  appApkVersion: version,
  appApkSize: String(size),
  appApkNotes: notes,
  appApkUpdatedAt: new Date().toISOString(),
};

for (const [key, value] of Object.entries(values)) {
  await prisma.setting.upsert({
    where: { key },
    update: { value },
    create: { key, value },
  });
}

console.log(
  `Published v${version} (${(size / 1024 / 1024).toFixed(1)} MB) — live on /download`,
);

await prisma.$disconnect();
