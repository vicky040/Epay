'use server';

import { revalidatePath } from 'next/cache';

import { round2 } from '@/lib/api';
import { currentAdmin, hashPassword } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { setSetting, syncVipLevel } from '@/lib/earnings';

async function guard() {
  const admin = await currentAdmin();
  if (!admin) throw new Error('Not authorised');
  return admin;
}

const str = (f: FormData, k: string) => String(f.get(k) ?? '').trim();
const num = (f: FormData, k: string, d = 0) => {
  const v = Number(f.get(k));
  return Number.isFinite(v) ? v : d;
};
const int = (f: FormData, k: string, d = 0) => Math.trunc(num(f, k, d));
const bool = (f: FormData, k: string) => f.get(k) === 'on' || f.get(k) === 'true';

// ------------------------------------------------------------------ users --

export async function adjustBalance(formData: FormData) {
  await guard();
  const userId = str(formData, 'userId');
  const field = str(formData, 'field'); // rechargeBalance | withdrawBalance
  const amount = round2(num(formData, 'amount'));
  const note = str(formData, 'note') || 'Manual adjustment by admin';

  if (!['rechargeBalance', 'withdrawBalance'].includes(field)) {
    throw new Error('Invalid balance field');
  }
  if (!amount) throw new Error('Enter a non-zero amount');

  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { [field]: { increment: amount } },
    }),
    prisma.transaction.create({
      data: {
        userId,
        type: amount > 0 ? 'bonus' : 'purchase',
        amount: Math.abs(amount),
        status: 'success',
        note,
      },
    }),
  ]);

  revalidatePath('/admin/users');
  revalidatePath(`/admin/users/${userId}`);
}

export async function setUserStatus(formData: FormData) {
  await guard();
  const userId = str(formData, 'userId');
  const status = str(formData, 'status');
  await prisma.user.update({ where: { id: userId }, data: { status } });
  revalidatePath('/admin/users');
  revalidatePath(`/admin/users/${userId}`);
}

export async function setUserVip(formData: FormData) {
  await guard();
  const userId = str(formData, 'userId');
  await prisma.user.update({
    where: { id: userId },
    data: { vipLevel: int(formData, 'vipLevel') },
  });
  revalidatePath(`/admin/users/${userId}`);
}

export async function grantDraws(formData: FormData) {
  await guard();
  const userId = str(formData, 'userId');
  await prisma.user.update({
    where: { id: userId },
    data: { drawChances: { increment: int(formData, 'draws', 1) } },
  });
  revalidatePath(`/admin/users/${userId}`);
}

export async function resetUserPassword(formData: FormData) {
  await guard();
  const userId = str(formData, 'userId');
  const password = str(formData, 'password');
  if (password.length < 6) throw new Error('Password must be at least 6 characters');
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash: await hashPassword(password) },
  });
  revalidatePath(`/admin/users/${userId}`);
}

// --------------------------------------------------------------- products --

export async function saveProduct(formData: FormData) {
  await guard();
  const id = str(formData, 'id');
  const data = {
    title: str(formData, 'title'),
    image: str(formData, 'image'),
    category: str(formData, 'category') || 'steady',
    vipRequired: int(formData, 'vipRequired'),
    price: num(formData, 'price'),
    periodEarning: num(formData, 'periodEarning'),
    duration: int(formData, 'duration', 1),
    cycleUnit: str(formData, 'cycleUnit') || 'Days',
    total: num(formData, 'total'),
    maxPerUser: int(formData, 'maxPerUser', 1),
    hot: bool(formData, 'hot'),
    active: bool(formData, 'active'),
    sortOrder: int(formData, 'sortOrder'),
  };
  if (!data.title) throw new Error('Title is required');
  if (data.price <= 0) throw new Error('Price must be greater than zero');

  if (id) await prisma.product.update({ where: { id }, data });
  else await prisma.product.create({ data });

  revalidatePath('/admin/products');
}

export async function deleteProduct(formData: FormData) {
  await guard();
  const id = str(formData, 'id');
  const used = await prisma.order.count({ where: { productId: id } });
  if (used > 0) {
    // Keep the history intact — retire it instead of deleting.
    await prisma.product.update({ where: { id }, data: { active: false } });
  } else {
    await prisma.product.delete({ where: { id } });
  }
  revalidatePath('/admin/products');
}

// ----------------------------------------------------- recharge / withdraw --

export async function approveTransaction(formData: FormData) {
  await guard();
  const id = str(formData, 'id');

  const txn = await prisma.transaction.findUnique({ where: { id } });
  if (!txn) throw new Error('Transaction not found');
  if (txn.status !== 'pending') throw new Error('Already processed');

  if (txn.type === 'recharge') {
    await prisma.$transaction([
      prisma.transaction.update({
        where: { id },
        data: { status: 'success', note: 'Confirmed by admin' },
      }),
      prisma.user.update({
        where: { id: txn.userId },
        data: { rechargeBalance: { increment: txn.amount } },
      }),
    ]);
    // first_recharge task
    const task = await prisma.task.findUnique({ where: { key: 'first_recharge' } });
    if (task) {
      await prisma.taskProgress.upsert({
        where: { userId_taskId: { userId: txn.userId, taskId: task.id } },
        update: { progress: task.target },
        create: { userId: txn.userId, taskId: task.id, progress: task.target },
      });
    }
  } else {
    // Withdrawals already debited the balance when requested.
    await prisma.transaction.update({
      where: { id },
      data: { status: 'success', note: 'Paid out by admin' },
    });
  }

  revalidatePath('/admin/recharges');
  revalidatePath('/admin/withdrawals');
  revalidatePath('/admin');
}

export async function rejectTransaction(formData: FormData) {
  await guard();
  const id = str(formData, 'id');
  const reason = str(formData, 'reason') || 'Rejected by admin';

  const txn = await prisma.transaction.findUnique({ where: { id } });
  if (!txn) throw new Error('Transaction not found');
  if (txn.status !== 'pending') throw new Error('Already processed');

  if (txn.type === 'withdraw') {
    // Give the held funds back.
    await prisma.$transaction([
      prisma.transaction.update({
        where: { id },
        data: { status: 'rejected', note: reason },
      }),
      prisma.user.update({
        where: { id: txn.userId },
        data: { withdrawBalance: { increment: txn.amount } },
      }),
    ]);
  } else {
    await prisma.transaction.update({
      where: { id },
      data: { status: 'rejected', note: reason },
    });
  }

  revalidatePath('/admin/recharges');
  revalidatePath('/admin/withdrawals');
}

// ---------------------------------------------------------------- notices --

export async function saveNotice(formData: FormData) {
  await guard();
  const id = str(formData, 'id');
  const data = {
    title: str(formData, 'title'),
    image: str(formData, 'image'),
    body: str(formData, 'body'),
    pinned: bool(formData, 'pinned'),
    published: bool(formData, 'published'),
  };
  if (!data.title) throw new Error('Title is required');

  if (id) await prisma.notice.update({ where: { id }, data });
  else await prisma.notice.create({ data });

  revalidatePath('/admin/notices');
}

export async function deleteNotice(formData: FormData) {
  await guard();
  await prisma.notice.delete({ where: { id: str(formData, 'id') } });
  revalidatePath('/admin/notices');
}

// ------------------------------------------------------------------ blogs --

export async function reviewBlog(formData: FormData) {
  await guard();
  const id = str(formData, 'id');
  const decision = str(formData, 'decision'); // approved | rejected
  const reward = round2(num(formData, 'reward'));

  const blog = await prisma.blog.findUnique({ where: { id } });
  if (!blog) throw new Error('Post not found');
  if (blog.status !== 'pending') throw new Error('Already reviewed');

  if (decision === 'approved') {
    await prisma.$transaction([
      prisma.blog.update({
        where: { id },
        data: { status: 'approved', reward },
      }),
      ...(reward > 0
        ? [
            prisma.user.update({
              where: { id: blog.userId },
              data: { withdrawBalance: { increment: reward } },
            }),
            prisma.transaction.create({
              data: {
                userId: blog.userId,
                type: 'bonus',
                amount: reward,
                status: 'success',
                note: 'Blog reward',
              },
            }),
          ]
        : []),
    ]);
  } else {
    await prisma.blog.update({ where: { id }, data: { status: 'rejected' } });
  }

  revalidatePath('/admin/blogs');
}

// ---------------------------------------------------------------- banners --

export async function saveBanner(formData: FormData) {
  await guard();
  const id = str(formData, 'id');
  const data = {
    image: str(formData, 'image'),
    link: str(formData, 'link') || null,
    sortOrder: int(formData, 'sortOrder'),
    active: bool(formData, 'active'),
  };
  if (!data.image) throw new Error('Image URL is required');

  if (id) await prisma.bannerItem.update({ where: { id }, data });
  else await prisma.bannerItem.create({ data });

  revalidatePath('/admin/banners');
}

export async function deleteBanner(formData: FormData) {
  await guard();
  await prisma.bannerItem.delete({ where: { id: str(formData, 'id') } });
  revalidatePath('/admin/banners');
}

// ------------------------------------------------------------------- vip ---

export async function saveVipTier(formData: FormData) {
  await guard();
  const level = int(formData, 'level');
  const data = {
    requiredAmount: num(formData, 'requiredAmount'),
    dailyBonus: num(formData, 'dailyBonus'),
    perks: str(formData, 'perks'),
  };
  await prisma.vipTier.upsert({
    where: { level },
    update: data,
    create: { level, ...data },
  });
  revalidatePath('/admin/vip');
}

export async function deleteVipTier(formData: FormData) {
  await guard();
  const level = int(formData, 'level');
  if (level === 0) throw new Error('VIP 0 cannot be removed');
  await prisma.vipTier.delete({ where: { level } });
  revalidatePath('/admin/vip');
}

// ----------------------------------------------------------------- tasks ---

export async function saveTask(formData: FormData) {
  await guard();
  const id = str(formData, 'id');
  const data = {
    key: str(formData, 'key'),
    title: str(formData, 'title'),
    description: str(formData, 'description'),
    reward: num(formData, 'reward'),
    target: int(formData, 'target', 1),
    active: bool(formData, 'active'),
    sortOrder: int(formData, 'sortOrder'),
  };
  if (!data.key || !data.title) throw new Error('Key and title are required');

  if (id) await prisma.task.update({ where: { id }, data });
  else await prisma.task.create({ data });

  revalidatePath('/admin/tasks');
}

export async function deleteTask(formData: FormData) {
  await guard();
  await prisma.task.delete({ where: { id: str(formData, 'id') } });
  revalidatePath('/admin/tasks');
}

// ----------------------------------------------------------------- lucky ---

export async function saveLuckyPrize(formData: FormData) {
  await guard();
  const slot = int(formData, 'slot');
  const data = {
    amount: num(formData, 'amount'),
    weight: int(formData, 'weight', 10),
  };
  await prisma.luckyPrize.upsert({
    where: { slot },
    update: data,
    create: { slot, ...data },
  });
  revalidatePath('/admin/lucky');
}

// -------------------------------------------------------------- settings ---

export async function saveSettings(formData: FormData) {
  await guard();
  const keys = [
    'appName',
    'activationReward',
    'rebateL1',
    'rebateL2',
    'rebateL3',
    'minRecharge',
    'minWithdraw',
    'withdrawTaxPercent',
    'blogReward',
    'supportHours',
    'telegramUrl',
    'publicUrl',
  ];
  for (const k of keys) {
    if (formData.has(k)) await setSetting(k, str(formData, k));
  }
  revalidatePath('/admin/settings');
}

// ---------------------------------------------------------------- orders ---

export async function settleOrder(formData: FormData) {
  await guard();
  const id = str(formData, 'id');
  const order = await prisma.order.findUnique({ where: { id } });
  if (!order) throw new Error('Order not found');

  await prisma.order.update({
    where: { id },
    data: { status: 'finished', cyclesPaid: order.duration },
  });
  await syncVipLevel(order.userId);
  revalidatePath('/admin/orders');
}

// ------------------------------------------------------------- app links ---

export async function saveAppLinks(formData: FormData) {
  await guard();
  await setSetting('appIosUrl', str(formData, 'appIosUrl'));
  await setSetting('appWebUrl', str(formData, 'appWebUrl'));
  revalidatePath('/admin/app');
  revalidatePath('/download');
}
