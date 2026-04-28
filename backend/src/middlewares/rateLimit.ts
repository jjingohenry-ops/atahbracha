import { NextFunction, Request, Response } from 'express';

type RateLimitOptions = {
  windowMs: number;
  max: number;
  keyPrefix: string;
};

type HitBucket = {
  count: number;
  resetAt: number;
};

const buckets = new Map<string, HitBucket>();

const clientKey = (req: Request, keyPrefix: string): string => {
  const user = (req as any).user;
  const userId = user?.uid || user?.userId;
  const forwarded = req.headers['x-forwarded-for'];
  const forwardedIp = Array.isArray(forwarded)
    ? forwarded[0]
    : forwarded?.split(',')[0]?.trim();

  return `${keyPrefix}:${userId || forwardedIp || req.ip || req.socket.remoteAddress || 'unknown'}`;
};

export const createRateLimiter = ({ windowMs, max, keyPrefix }: RateLimitOptions) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const now = Date.now();
    const key = clientKey(req, keyPrefix);
    const existing = buckets.get(key);

    if (!existing || existing.resetAt <= now) {
      buckets.set(key, { count: 1, resetAt: now + windowMs });
      next();
      return;
    }

    existing.count += 1;

    if (existing.count > max) {
      const retryAfterSeconds = Math.ceil((existing.resetAt - now) / 1000);
      res.setHeader('Retry-After', retryAfterSeconds.toString());
      res.status(429).json({
        success: false,
        error: 'Too many requests. Please slow down and try again.',
      });
      return;
    }

    next();
  };
};

setInterval(() => {
  const now = Date.now();
  for (const [key, bucket] of buckets.entries()) {
    if (bucket.resetAt <= now) {
      buckets.delete(key);
    }
  }
}, 5 * 60 * 1000).unref();
