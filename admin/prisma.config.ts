import path from 'node:path';

import dotenv from 'dotenv';

// .env.local holds the Vercel-pulled DATABASE_URL and wins over .env.
dotenv.config({ path: '.env.local' });
dotenv.config({ path: '.env' });

import { defineConfig, env } from 'prisma/config';

export default defineConfig({
  schema: path.join('prisma', 'schema.prisma'),
  datasource: {
    url: env('DATABASE_URL'),
  },
  migrations: {
    seed: 'tsx prisma/seed.ts',
  },
});
