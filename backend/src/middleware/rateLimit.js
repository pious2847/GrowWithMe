'use strict';

/**
 * Small dependency-free fixed-window rate limiter.
 *
 * A single backend instance is enough for the current deployment (Render,
 * one web service). The store is in-process by design: if the service scales
 * horizontally, swap the Map for Redis — the middleware signature stays the
 * same. Key buckets are per route + caller so one noisy endpoint cannot lock
 * a caregiver out of another.
 */

const buckets = new Map();
let lastSweep = 0;

function sweep(now) {
  // Amortised cleanup: at most once a minute, drop expired buckets so the
  // Map cannot grow without bound under scanning traffic.
  if (now - lastSweep < 60_000) return;
  lastSweep = now;
  for (const [key, bucket] of buckets) {
    if (bucket.resetAt <= now) buckets.delete(key);
  }
}

/**
 * @param {object} opts
 * @param {number} opts.windowMs  window length in milliseconds
 * @param {number} opts.max       requests allowed per window
 * @param {(req) => string} [opts.key] bucket key (defaults to IP)
 * @param {string} [opts.message] 429 message shown to the caller
 */
function rateLimit({ windowMs = 60_000, max = 60, key, message } = {}) {
  return function limit(req, res, next) {
    if (process.env.RATE_LIMIT_DISABLED === 'true') return next();

    const now = Date.now();
    sweep(now);

    const caller = (typeof key === 'function' ? key(req) : null) || req.ip || 'unknown';
    const route = `${req.method} ${req.baseUrl || ''}${req.path}`;
    const bucketKey = `${route}|${caller}`;

    let bucket = buckets.get(bucketKey);
    if (!bucket || bucket.resetAt <= now) {
      bucket = { count: 0, resetAt: now + windowMs };
      buckets.set(bucketKey, bucket);
    }
    bucket.count += 1;

    const remaining = Math.max(0, max - bucket.count);
    res.setHeader('X-RateLimit-Limit', String(max));
    res.setHeader('X-RateLimit-Remaining', String(remaining));
    res.setHeader('X-RateLimit-Reset', String(Math.ceil(bucket.resetAt / 1000)));

    if (bucket.count > max) {
      const retryAfter = Math.max(1, Math.ceil((bucket.resetAt - now) / 1000));
      res.setHeader('Retry-After', String(retryAfter));
      return res.status(429).json({
        success: false,
        message:
          message || 'Too many requests. Please wait a moment and try again.',
        retryAfterSeconds: retryAfter,
      });
    }
    next();
  };
}

/** Caller key for phone-based limits. Uses the last 9 digits so "+233 24 000
 * 0001" and "024 000 0001" share one bucket instead of letting the caller
 * dodge the limit by changing the number format. */
function phoneKey(req) {
  const digits = String(req.body?.phone || '').replace(/\D/g, '');
  return (digits.length > 9 ? digits.slice(-9) : digits) || req.ip || 'unknown';
}

function userKey(req) {
  return req.user?._id ? String(req.user._id) : req.ip || 'unknown';
}

/** Test helper. */
function resetRateLimits() {
  buckets.clear();
}

module.exports = { rateLimit, phoneKey, userKey, resetRateLimits };
