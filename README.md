# EPay

A complete investment & earning platform: a Flutter mobile app, a REST backend,
and a web admin console.

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

Data lives in SQLite through Prisma 7 (swap the adapter for Postgres/MySQL in
production — only `src/lib/db.ts` and `prisma.config.ts` change).

### Run it

```bash
cd admin
npm install
npm run db:push      # create the SQLite schema
npm run db:seed      # products, VIP tiers, notices, tasks, prizes, admin user
npm run dev          # http://localhost:3000
```

Open **http://localhost:3000/admin**.

| Account | Login | Password |
| --- | --- | --- |
| Admin console | `9000000000` | `admin123` |
| Demo app user | `8769293125` | `demo123` |

> Change both before deploying. `npm run db:reset` wipes and re-seeds.

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

## 3. Brand

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

- [ ] Replace both JWT secrets and the seeded admin password
- [ ] Swap SQLite for Postgres (change the Prisma adapter in `src/lib/db.ts`)
- [ ] Wire a real SMS gateway in `src/app/api/auth/otp/route.ts`
- [ ] Restrict `Access-Control-Allow-Origin` in `next.config.ts`
- [ ] Put the app's `API_BASE_URL` behind HTTPS
