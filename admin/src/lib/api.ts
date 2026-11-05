import { NextResponse } from 'next/server';
import { ZodError } from 'zod';

export const json = <T>(data: T, init?: number | ResponseInit) =>
  NextResponse.json(data, typeof init === 'number' ? { status: init } : init);

export const fail = (message: string, status = 400) =>
  NextResponse.json({ error: message }, { status });

export const unauthorized = () => fail('Not authenticated', 401);
export const forbidden = () => fail('Not allowed', 403);
export const notFound = (what = 'Resource') => fail(`${what} not found`, 404);

/** Wraps a handler so thrown errors become clean JSON instead of a 500 page. */
export function handler<A extends unknown[]>(
  fn: (...args: A) => Promise<Response>,
) {
  return async (...args: A): Promise<Response> => {
    try {
      return await fn(...args);
    } catch (e) {
      if (e instanceof ZodError) {
        const first = e.issues[0];
        return fail(first?.message ?? 'Invalid request', 422);
      }
      const message = e instanceof Error ? e.message : 'Unexpected error';
      console.error('[api]', e);
      return fail(message, 400);
    }
  };
}

export const parseJsonArray = (value: string): string[] => {
  try {
    const v = JSON.parse(value);
    return Array.isArray(v) ? v.map(String) : [];
  } catch {
    return [];
  }
};

export const round2 = (n: number) => Math.round(n * 100) / 100;
