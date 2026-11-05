import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { cookies } from 'next/headers';
import { NextRequest } from 'next/server';

import { prisma } from './db';

const JWT_SECRET = process.env.JWT_SECRET || 'epay-dev-secret';
const ADMIN_JWT_SECRET = process.env.ADMIN_JWT_SECRET || 'epay-admin-dev-secret';
const ADMIN_COOKIE = 'epay_admin';

export type JwtPayload = { sub: string; phone: string };

// ---------------------------------------------------------------- passwords --

export const hashPassword = (plain: string) => bcrypt.hash(plain, 10);
export const verifyPassword = (plain: string, hash: string) =>
  bcrypt.compare(plain, hash);

// ------------------------------------------------------------- app (mobile) --

export function signAppToken(userId: string, phone: string) {
  return jwt.sign({ sub: userId, phone }, JWT_SECRET, { expiresIn: '30d' });
}

export function readBearer(req: NextRequest): JwtPayload | null {
  const header = req.headers.get('authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return null;
  try {
    return jwt.verify(token, JWT_SECRET) as JwtPayload;
  } catch {
    return null;
  }
}

/** Resolves the signed-in app user, or null. */
export async function currentUser(req: NextRequest) {
  const payload = readBearer(req);
  if (!payload) return null;
  const user = await prisma.user.findUnique({ where: { id: payload.sub } });
  if (!user || user.status !== 'active') return null;
  return user;
}

// --------------------------------------------------------------- admin panel --

export function signAdminToken(userId: string) {
  return jwt.sign({ sub: userId, role: 'admin' }, ADMIN_JWT_SECRET, {
    expiresIn: '12h',
  });
}

export async function setAdminCookie(token: string) {
  const store = await cookies();
  store.set(ADMIN_COOKIE, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: 60 * 60 * 12,
  });
}

export async function clearAdminCookie() {
  const store = await cookies();
  store.delete(ADMIN_COOKIE);
}

/** Reads the admin session from the cookie jar (server components / route handlers). */
export async function currentAdmin() {
  const store = await cookies();
  const token = store.get(ADMIN_COOKIE)?.value;
  if (!token) return null;
  try {
    const payload = jwt.verify(token, ADMIN_JWT_SECRET) as { sub: string };
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    return user?.isAdmin ? user : null;
  } catch {
    return null;
  }
}

/** Same check, but reading the cookie off a NextRequest (used by API routes). */
export function readAdminFromRequest(req: NextRequest) {
  const token = req.cookies.get(ADMIN_COOKIE)?.value;
  if (!token) return null;
  try {
    return jwt.verify(token, ADMIN_JWT_SECRET) as { sub: string };
  } catch {
    return null;
  }
}

export async function requireAdmin(req: NextRequest) {
  const payload = readAdminFromRequest(req);
  if (!payload) return null;
  const user = await prisma.user.findUnique({ where: { id: payload.sub } });
  return user?.isAdmin ? user : null;
}

// -------------------------------------------------------------------- misc --

export function generateInviteCode() {
  return Math.random().toString(36).slice(2, 7).toUpperCase();
}

export function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}
