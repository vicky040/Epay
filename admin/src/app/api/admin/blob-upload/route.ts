import { handleUpload, type HandleUploadBody } from '@vercel/blob/client';
import { NextRequest } from 'next/server';

import { fail, handler, json } from '@/lib/api';
import { requireAdmin } from '@/lib/auth';

/**
 * Issues a short-lived client upload token so the browser can send the APK
 * straight to Vercel Blob. Vercel caps function request bodies at 4.5 MB, so a
 * ~50 MB build can never be proxied through a route handler.
 */
export const POST = handler(async (req: NextRequest) => {
  const admin = await requireAdmin(req);
  if (!admin) return fail('Not allowed', 403);

  const body = (await req.json()) as HandleUploadBody;

  const result = await handleUpload({
    body,
    request: req,
    onBeforeGenerateToken: async () => ({
      allowedContentTypes: [
        'application/vnd.android.package-archive',
        'application/octet-stream',
        'application/zip',
      ],
      maximumSizeInBytes: 300 * 1024 * 1024,
      addRandomSuffix: true,
    }),
    onUploadCompleted: async () => {
      // The admin page persists the release metadata once the upload resolves.
    },
  });

  return json(result);
});
