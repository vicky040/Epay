import type { Blog, Order, Product, Transaction, User, Notice } from '@prisma/client';

import { parseJsonArray } from './api';

const isSameDay = (a: Date | null, b: Date) =>
  !!a &&
  a.getFullYear() === b.getFullYear() &&
  a.getMonth() === b.getMonth() &&
  a.getDate() === b.getDate();

export function publicUser(u: User) {
  return {
    id: u.id,
    phone: u.phone,
    nickname: u.nickname,
    avatar: u.avatar,
    inviteCode: u.inviteCode,
    vipLevel: u.vipLevel,
    rechargeBalance: u.rechargeBalance,
    withdrawBalance: u.withdrawBalance,
    productIncome: u.productIncome,
    totalInvested: u.totalInvested,
    drawChances: u.drawChances,
    checkedInToday: isSameDay(u.lastCheckIn, new Date()),
    createdAt: u.createdAt,
  };
}

export function publicProduct(p: Product) {
  return {
    id: p.id,
    title: p.title,
    image: p.image,
    category: p.category,
    vipRequired: p.vipRequired,
    price: p.price,
    periodEarning: p.periodEarning,
    duration: p.duration,
    cycleUnit: p.cycleUnit,
    total: p.total,
    maxPerUser: p.maxPerUser,
    hot: p.hot,
    active: p.active,
  };
}

export function publicOrder(o: Order) {
  return {
    id: o.id,
    productTitle: o.productTitle,
    productImage: o.productImage,
    shares: o.shares,
    amount: o.amount,
    earnedSoFar: o.earnedSoFar,
    expectedTotal: o.expectedTotal,
    status: o.status,
    createdAt: o.createdAt,
    endsAt: o.endsAt,
  };
}

export function publicTxn(t: Transaction) {
  return {
    id: t.id,
    type: t.type,
    amount: t.amount,
    status: t.status,
    note: t.note,
    createdAt: t.createdAt,
  };
}

export function publicNotice(n: Notice) {
  return {
    id: n.id,
    title: n.title,
    image: n.image,
    body: n.body,
    createdAt: n.createdAt,
  };
}

const maskPhone = (p: string) =>
  p.length < 6 ? p : `${p.slice(0, 2)}****${p.slice(-2)}`;

export function publicBlog(b: Blog & { user?: { phone: string } | null }) {
  return {
    id: b.id,
    authorPhone: b.user ? maskPhone(b.user.phone) : '',
    content: b.content,
    photos: parseJsonArray(b.photos),
    reward: b.reward,
    createdAt: b.createdAt,
  };
}
