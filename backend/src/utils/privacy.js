'use strict';

const crypto = require('crypto');

/**
 * Privacy helpers for logs.
 *
 * The backend handles caregivers' phone numbers and health context; neither
 * belongs in plaintext in log files or third-party log drains. Operators still
 * need to correlate a support report with a request, so we keep the dial code
 * and the last two digits and mask everything between.
 */

function maskPhone(value) {
  if (value === null || value === undefined || value === '') return 'unknown';
  const raw = String(value).trim();
  const digits = raw.replace(/\D/g, '');
  if (!digits) return 'unknown';
  if (digits.length <= 4) return '*'.repeat(digits.length);
  const tail = digits.slice(-2);
  const head = raw.startsWith('+') && digits.length > 6 ? `+${digits.slice(0, 3)}` : '';
  const visible = head ? 3 : 0;
  const stars = Math.max(2, digits.length - visible - 2);
  return `${head}${'*'.repeat(stars)}${tail}`;
}

/**
 * A short, stable pseudonym for a user document. Useful when debugging a
 * sequence of requests without writing an account id (which is directly
 * linkable to a health record) to disk.
 */
function userRef(user) {
  if (!user) return 'anon';
  if (user._id) {
    const hash = crypto.createHash('sha256').update(String(user._id)).digest('hex');
    return `user_${hash.slice(0, 8)}`;
  }
  return maskPhone(user.phone);
}

module.exports = { maskPhone, userRef };
