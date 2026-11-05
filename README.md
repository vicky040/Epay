# EPay

A complete investment & earning platform: a Flutter mobile app, a REST backend,
and a web admin console.

**Live:**

| | URL |
| --- | --- |
| Admin console | https://epay-admin-phi.vercel.app/admin |
| App download page | https://epay-admin-phi.vercel.app/download |
| API base | https://epay-admin-phi.vercel.app/api |
| Repository | https://github.com/vicky040/Epay |

```
capp/
├─ epay/     Flutter app (Android · iOS · Web)
└─ admin/    Next.js — REST backend for the app + admin console
```

---

## 1. Backend + admin console (`admin/`)

Next.js 16 (App Router) serving two things from one project:

* `**/api/*`** — the JSON REST API the Flutter app talks to
* `**/admin/***` — the web console for running the platform

Data lives in Postgres (Neon) through Prisma 7 with the `@prisma/adapter-neon`
driver adapter.

### Run it

```bash
cd admin
npm install
vercel env pull .env.local --yes   # pulls DATABASE_URL and the JWT secrets
npm run db:push                    # create the schema
npm run db:seed                    # products, VIP tiers, notices, tasks, prizes, admin user
npm run dev                        # http://localhost:3000
```

Without Vercel, copy `.env.example` to `.env.local` and fill in your own
Postgres connection string.

Open **http://localhost:3000/admin**.

| Account | Login | Password |
| --- | --- | --- |
| Admin console | `9000000000` | `admin123` |
| Demo app user | `8769293125` | `demo123` |

> **Change the admin password immediately** — Settings → *Your admin password*.
> `npm run db:reset` wipes and re-seeds.

### Admin console

| Page | What it does |
| --- | --- |
| Dashboard | Users, volume, deposits, payouts, action queue |
| Users | Search, filter, freeze; per-user detail with balance adjustment, VIP override, password reset, bank details, order & transaction history |
| Orders | Every investment, payout progress, close an order early |
| Recharges | Confirm a deposit → credits the user's recharge balance |
| Withdrawals | Mark paid or reject (rejecting refunds the held amount) |
| Products | Full CRUD for the three catalogue tabs (Steady / Benefits / Event) |
| VIP Tiers | Thresholds, daily check-in bonus, perks |
| Banners | Home-screen carousel |
| Notices | Announcements shown in the app |
| Blog Review | Approve a post and set the author's reward |
| Tasks | Reward missions and their target counts |
| Lucky Wheel | Prize slots, weights, live odds, win log |
| Mobile App | Upload an APK release, QR code, and the public download link |
| Reports | 14-day cash flow, totals by type, top referrers |
| Settings | Minimums, withdrawal tax, referral rebate percentages, branding |

### Money rules

* **Recharges** stay `pending` until an admin confirms, then credit
  `rechargeBalance`.
* **Purchases** spend `rechargeBalance` and raise `totalInvested` (which drives
  the VIP level).
* **Returns** accrue lazily: whenever a user's data is read, every elapsed cycle
  since the last payout is credited to `withdrawBalance` exactly once
  (`cyclesPaid` is the ledger). No cron job required.
* **Withdrawals** debit `withdrawBalance` immediately and sit `pending`;
  rejecting refunds it.
* **Referral rebates** pay 3 levels up on every purchase, at the percentages set
  in Settings.

### API

Auth is a bearer JWT from login/register. Admin routes use an HTTP-only cookie.

```
POST   /api/auth/otp              { phone }
POST   /api/auth/register         { phone, password, nickname, inviteCode?, otp }
POST   /api/auth/login            { phone, password }
GET    /api/me                    → profile + balances
PATCH  /api/me                    { nickname?, avatar? }
GET    /api/banners
GET    /api/products?category=steady|benefits|event
GET    /api/vip-levels
GET    /api/orders?status=all|active|finished
POST   /api/orders                { productId, shares }
GET    /api/transactions?type=…
POST   /api/recharge              { amount, method }
POST   /api/withdraw              { amount }
GET    /api/bank-card
POST   /api/bank-card             { holder, accountNumber, ifsc, bankName, upi? }
GET    /api/team
GET    /api/notices
GET    /api/blogs
POST   /api/blogs                 { content, photos[] }
GET    /api/tasks
POST   /api/tasks/:id/claim
POST   /api/checkin
GET    /api/lucky
POST   /api/lucky/spin
```

In development `POST /api/auth/otp` returns the code as `devCode` so you can sign
up without an SMS gateway. Set `SKIP_OTP=true` to bypass verification entirely.

### Environment

`admin/.env`:

```ini
DATABASE_URL="file:./dev.db"
JWT_SECRET="change-me"
ADMIN_JWT_SECRET="change-me-too"
APP_PUBLIC_URL="https://epay.app"
```

---

## 2. Flutter app (`epay/`)

```bash
cd epay
flutter pub get
flutter run
```

The app points at the deployed backend by default, so it works straight away.
To run it against a local backend:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

`10.0.2.2` is the Android emulator's alias for your machine's localhost. Use your
LAN IP for a physical device, or `http://localhost:3000/api` for Flutter web.

**If the backend is unreachable the app falls back to a bundled demo dataset**, so
every screen stays explorable offline. Turn that off with
`--dart-define=DEMO_FALLBACK=false`.

### Screens

Auth (login / sign-up with OTP & invite code) · Home · Invest (Steady /
Benefits / Event, list & grid views, purchase sheet) · Notice + detail · Blog +
Post Blog · Account · Settings · Balance Record · My Orders · VIP Levels ·
Team Details · Recharge · Withdraw · Bank Card · Tasks · Daily Check-in ·
Lucky Wheel · Help Center.

### Structure

```
lib/
├─ core/        theme, API client, session, demo data, shared widgets
├─ models/      typed models
└─ screens/     one folder per feature area
```

---

## 3. Shipping the mobile app

The admin console hosts the Android build and the page your users install from.

**Build the APK:**

```bash
cd epay
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk  (~51 MB)
```

**Publish it:** open **Admin → Mobile App**, drop in the `.apk`, set a version
and release notes, then *Publish release*. The file uploads straight from your
browser to Vercel Blob — Vercel caps function request bodies at 4.5 MB, so a
50 MB APK can never be proxied through a route handler.

**Users install from** `/download`: a branded page with a download button, a QR
code to open it on a phone, install steps for side-loading, and the current
version and size. Optional iOS and web-app links appear there too once set.

APKs are deliberately **not** committed to git — they live in Blob storage.

---

## 4. Brand

Professional blue, built from one token set in `epay/lib/core/theme.dart`:

| Token | Hex |
| --- | --- |
| Navy | `#0A2A5E` |
| Primary | `#1557D6` |
| Sky | `#2E9BF0` |
| Cyan | `#5CC8F5` |
| Gold (VIP) | `#F2A516` |

The **logo** is an "E" with a rising arrow — payments plus growth. It ships as:

* `epay/assets/images/logo_mark.png` (1024px, rounded)
* `logo_512.png`, `logo_192.png`, `logo_mark_square.png`
* `logo_wordmark.png` / `logo_wordmark_white.png`
* Installed Android mipmaps, iOS AppIcon set, and web icons
* Drawn in code as `EpayLogo` (Flutter) and `EpayMark` (React) so it stays crisp
  at any size

Regenerate the raster files with `tools/logo.py` and `tools/icons.py`.

---

## Production checklist

- [x] Postgres (Neon) in place of SQLite
- [x] JWT secrets generated and stored as Vercel secrets
- [x] App talks to the backend over HTTPS
- [ ] **Change the seeded admin password** (Settings → Your admin password)
- [ ] **Change or remove the seeded demo user** (`8769293125` / `demo123`)
- [ ] Wire a real SMS gateway in `src/app/api/auth/otp/route.ts` — OTP currently
      returns `devCode` outside production
- [ ] Restrict `Access-Control-Allow-Origin` in `next.config.ts` to your own origins
- [ ] Rotate the Neon database password if the connection string was ever shared
- [ ] Run `vercel git connect` to deploy automatically on every push
