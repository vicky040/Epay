import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // The admin console renders live database state on every request, so the
  // Cache Components model adds nothing here and conflicts with the
  // `force-dynamic` segments each page needs.
  cacheComponents: false,

  images: {
    // Product / banner / avatar artwork is supplied as arbitrary URLs by the
    // operator, so allow any https host. Images render unoptimized.
    remotePatterns: [{ protocol: 'https', hostname: '**' }],
  },

  // The Flutter client (and the Flutter web build in particular) calls these
  // routes from a different origin.
  async headers() {
    return [
      {
        source: '/api/:path((?!admin).*)',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: '*' },
          {
            key: 'Access-Control-Allow-Methods',
            value: 'GET,POST,PATCH,DELETE,OPTIONS',
          },
          {
            key: 'Access-Control-Allow-Headers',
            value: 'Content-Type, Authorization',
          },
        ],
      },
    ];
  },

  turbopack: {
    rules: {
      '*.css': {
        loaders: ['@tailwindcss/turbopack'],
        as: '*.css',
      },
    },
  },
};

export default nextConfig;
