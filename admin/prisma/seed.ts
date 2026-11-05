import dotenv from 'dotenv';

dotenv.config({ path: '.env.local' });
dotenv.config({ path: '.env' });

import { PrismaNeon } from '@prisma/adapter-neon';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not set. Run `vercel env pull .env.local` first.');
}
const prisma = new PrismaClient({ adapter: new PrismaNeon({ connectionString }) });

const IMG = {
  tower:
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=900&q=70',
  plant:
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=900&q=70',
  port: 'https://images.unsplash.com/photo-1494412574643-ff11b0a5c1c3?w=900&q=70',
  machine:
    'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=900&q=70',
  solar:
    'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=900&q=70',
  city: 'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=900&q=70',
};

async function main() {
  console.log('Seeding EPay database…');

  // ----------------------------------------------------------- settings ----
  const settings: Record<string, string> = {
    appName: 'EPay',
    activationReward: '100',
    rebateL1: '60',
    rebateL2: '4',
    rebateL3: '1',
    minRecharge: '100',
    minWithdraw: '100',
    withdrawTaxPercent: '5',
    blogReward: '22',
    supportHours: '08:00 — 20:00 IST',
    telegramUrl: 'https://t.me/epay_official',
    publicUrl: 'https://epay.app',
  };
  for (const [key, value] of Object.entries(settings)) {
    await prisma.setting.upsert({ where: { key }, update: {}, create: { key, value } });
  }

  // --------------------------------------------------------- vip tiers ----
  const tiers = [
    { level: 0, requiredAmount: 0, dailyBonus: 0, perks: 'Browse products and daily blog rewards' },
    { level: 1, requiredAmount: 280, dailyBonus: 6, perks: 'Unlock Benefits products, 60% L1 rebate' },
    { level: 2, requiredAmount: 4800, dailyBonus: 16, perks: 'Higher daily cap and faster withdrawals' },
    { level: 3, requiredAmount: 9800, dailyBonus: 36, perks: 'Priority support channel' },
    { level: 4, requiredAmount: 28000, dailyBonus: 166, perks: 'Exclusive event products' },
    { level: 5, requiredAmount: 68000, dailyBonus: 366, perks: 'Dedicated account manager' },
    { level: 6, requiredAmount: 150000, dailyBonus: 666, perks: 'Zero withdrawal fee' },
    { level: 7, requiredAmount: 300000, dailyBonus: 766, perks: 'Top-tier partner benefits' },
  ];
  for (const t of tiers) {
    await prisma.vipTier.upsert({ where: { level: t.level }, update: t, create: t });
  }

  // ---------------------------------------------------------- products ----
  const products = [
    { title: 'Upgrade VIP1', image: IMG.tower, category: 'steady', vipRequired: 0, price: 280, periodEarning: 240.8, duration: 47, cycleUnit: 'Days', total: 11317.6, maxPerUser: 1, hot: false, sortOrder: 1 },
    { title: 'Upgrade VIP2', image: IMG.port, category: 'steady', vipRequired: 0, price: 4800, periodEarning: 4176, duration: 47, cycleUnit: 'Days', total: 196272, maxPerUser: 1, hot: false, sortOrder: 2 },
    { title: 'Upgrade VIP3', image: IMG.plant, category: 'steady', vipRequired: 0, price: 9800, periodEarning: 8526, duration: 47, cycleUnit: 'Days', total: 400722, maxPerUser: 1, hot: false, sortOrder: 3 },
    { title: 'Upgrade VIP4', image: IMG.city, category: 'steady', vipRequired: 0, price: 28000, periodEarning: 24360, duration: 47, cycleUnit: 'Days', total: 1144920, maxPerUser: 1, hot: false, sortOrder: 4 },

    { title: 'EPay Turbo B-X', image: IMG.machine, category: 'benefits', vipRequired: 1, price: 1599, periodEarning: 3731, duration: 1, cycleUnit: 'Hours', total: 3725.03, maxPerUser: 3, hot: true, sortOrder: 1 },
    { title: 'EPay Turbo B-X Pro', image: IMG.machine, category: 'benefits', vipRequired: 1, price: 3399, periodEarning: 9347.25, duration: 1, cycleUnit: 'Hours', total: 9332.29, maxPerUser: 3, hot: true, sortOrder: 2 },
    { title: 'EPay Turbo Max', image: IMG.solar, category: 'benefits', vipRequired: 2, price: 7999, periodEarning: 21877, duration: 1, cycleUnit: 'Hours', total: 21860, maxPerUser: 2, hot: false, sortOrder: 3 },

    { title: 'Festival Boost', image: IMG.machine, category: 'event', vipRequired: 1, price: 499, periodEarning: 673.65, duration: 23, cycleUnit: 'Days', total: 15493.95, maxPerUser: 5, hot: true, sortOrder: 1 },
    { title: 'Festival Boost Plus', image: IMG.plant, category: 'event', vipRequired: 1, price: 1399, periodEarning: 2308.35, duration: 23, cycleUnit: 'Days', total: 53092.05, maxPerUser: 5, hot: false, sortOrder: 2 },
    { title: 'Festival Boost Elite', image: IMG.port, category: 'event', vipRequired: 2, price: 2999, periodEarning: 4948.35, duration: 23, cycleUnit: 'Days', total: 113812.05, maxPerUser: 5, hot: false, sortOrder: 3 },
  ];
  if ((await prisma.product.count()) === 0) {
    for (const p of products) await prisma.product.create({ data: p });
  }

  // ----------------------------------------------------------- banners ----
  if ((await prisma.bannerItem.count()) === 0) {
    await prisma.bannerItem.createMany({
      data: [
        { image: IMG.city, sortOrder: 0 },
        { image: IMG.plant, sortOrder: 1 },
        { image: IMG.solar, sortOrder: 2 },
      ],
    });
  }

  // ----------------------------------------------------------- notices ----
  const notices = [
    {
      title: 'Cumulative Rewards',
      body: [
        '1: Cumulative top-up of 15,000: Reward of 1,000',
        '2: Cumulative top-up of 30,000: Reward of 3,000',
        '3: Cumulative top-up of 50,000: Reward of 6,000',
        'A: Total top-up of 30,000: Bonus awarded: 1,000 + 3,000',
        'B: Total top-up of 50,000: Bonus awarded: 1,000 + 3,000 + 6,000',
        'C: Once the conditions are met, the corresponding rewards will be automatically distributed; no manual claim is required.',
      ].join('\n\n'),
      pinned: true,
    },
    {
      title: 'Referral Rewards',
      body: [
        '1: Activate 10 Level 1 members to earn ₹1,000',
        '2: Activate 20 Level 1 members to earn ₹3,000',
        '3: Activate 50 Level 1 members to earn ₹10,000',
        '4: Activate 150 Level 1 members to earn ₹40,000',
        '5: Activate 500 Level 1 members to earn ₹150,000',
        '6: Blogs that charge fees are not eligible for this reward!',
        '7: Complete the corresponding task and contact customer service to claim your reward',
      ].join('\n'),
    },
    {
      title: 'Daily Bonuses',
      body: tiers
        .filter((t) => t.level > 0)
        .map((t) => `VIP${t.level}: Earn ₹${t.dailyBonus} for checking in every day`)
        .join('\n\n'),
    },
    {
      title: 'Lucky Draw',
      body: [
        '1: Purchase any item — for every 2 items bought, receive 2 chances to enter the draw, with no upper limit!',
        '2: Invite friends to join — for every 2 people invited, receive 2 chances to enter the draw, with no upper limit!',
      ].join('\n\n'),
    },
    {
      title: 'Official Channel',
      body:
        'Join the official EPay Telegram channel for the latest news, events and benefits. ' +
        'Beware of impostors — we never ask for your password or OTP.',
    },
  ];
  if ((await prisma.notice.count()) === 0) {
    for (const n of notices) await prisma.notice.create({ data: n });
  }

  // ------------------------------------------------------------- tasks ----
  const tasks = [
    { key: 'first_recharge', title: 'Complete your first recharge', description: 'Top up any amount to unlock withdrawals.', reward: 50, target: 1, sortOrder: 1 },
    { key: 'first_purchase', title: 'Buy your first product', description: 'Start earning daily returns.', reward: 80, target: 1, sortOrder: 2 },
    { key: 'invite_friends', title: 'Invite 3 friends', description: 'Earn ₹100 for every activated member.', reward: 300, target: 3, sortOrder: 3 },
    { key: 'checkin_streak', title: 'Check in for 7 days', description: 'Keep your streak alive for a bonus.', reward: 120, target: 7, sortOrder: 4 },
    { key: 'post_blog', title: 'Publish a blog post', description: 'Share your withdrawal proof with the community.', reward: 22, target: 1, sortOrder: 5 },
  ];
  for (const t of tasks) {
    await prisma.task.upsert({ where: { key: t.key }, update: {}, create: t });
  }

  // ------------------------------------------------------ lucky prizes ----
  const prizes = [
    { slot: 1, amount: 99988, weight: 1 },
    { slot: 2, amount: 48888, weight: 2 },
    { slot: 3, amount: 3888, weight: 5 },
    { slot: 4, amount: 988, weight: 12 },
    { slot: 5, amount: 288, weight: 25 },
    { slot: 6, amount: 28, weight: 60 },
    { slot: 7, amount: 18, weight: 120 },
    { slot: 8, amount: 8, weight: 200 },
  ];
  for (const p of prizes) {
    await prisma.luckyPrize.upsert({ where: { slot: p.slot }, update: p, create: p });
  }

  // ------------------------------------------------------------- admin ----
  const adminPhone = '9000000000';
  const admin = await prisma.user.upsert({
    where: { phone: adminPhone },
    update: { isAdmin: true },
    create: {
      phone: adminPhone,
      passwordHash: await bcrypt.hash('admin123', 10),
      nickname: 'Administrator',
      inviteCode: 'EPADMIN',
      isAdmin: true,
    },
  });

  // -------------------------------------------------------- demo member ---
  const demoPhone = '8769293125';
  const demo = await prisma.user.upsert({
    where: { phone: demoPhone },
    update: {},
    create: {
      phone: demoPhone,
      passwordHash: await bcrypt.hash('demo123', 10),
      nickname: 'Nic',
      inviteCode: '82777',
      rechargeBalance: 5000,
      withdrawBalance: 1250.5,
      referredById: admin.id,
    },
  });

  if ((await prisma.blog.count()) === 0) {
    await prisma.blog.createMany({
      data: [
        {
          userId: demo.id,
          content: 'Very fast withdrawal and very nice app, this is trustworthy.',
          photos: '[]',
          reward: 22,
          status: 'approved',
        },
        {
          userId: demo.id,
          content: 'Received my payout in 9 minutes. Thanks EPay team!',
          photos: '[]',
          reward: 18,
          status: 'approved',
        },
        {
          userId: demo.id,
          content: 'Third withdrawal completed today. Steady products work well for me.',
          photos: '[]',
          reward: 0,
          status: 'pending',
        },
      ],
    });
  }

  console.log('\nSeed complete.');
  console.log('  Admin console : 9000000000 / admin123');
  console.log('  Demo app user : 8769293125 / demo123');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
