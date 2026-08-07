const axios = require('axios');
const env = require('../config/env');
const logger = require('../utils/logger');

const ARKESEL_SMS_URL = 'https://sms.arkesel.com/api/v2/sms/send';

// Normalizes Ghanaian numbers to international format Arkesel expects (233XXXXXXXXX)
function normalizePhone(phone) {
  let p = String(phone).replace(/[\s\-+]/g, '');
  if (p.startsWith('0')) p = '233' + p.slice(1);
  return p;
}

/**
 * Sends an SMS via Arkesel. In development without an API key, logs to console
 * instead so the whole flow can be exercised locally.
 * Returns { ok, error? } and never throws — SMS failure must not break the API flow.
 */
async function sendSms(to, message) {
  const recipient = normalizePhone(to);
  if (!env.arkesel.apiKey) {
    logger.info(`[sms:dev] to=${recipient} :: ${message}`);
    return { ok: true, dev: true };
  }
  try {
    const res = await axios.post(
      ARKESEL_SMS_URL,
      { sender: env.arkesel.senderId, message, recipients: [recipient] },
      { headers: { 'api-key': env.arkesel.apiKey }, timeout: 15000 }
    );
    const ok = res.data && res.data.status === 'success';
    if (ok) logger.info(`[sms] sent to ${recipient} (${message.length} chars)`);
    else logger.error(`[sms] Arkesel rejected send to ${recipient}:`, res.data);
    return ok ? { ok: true } : { ok: false, error: JSON.stringify(res.data) };
  } catch (err) {
    const status = err.response && err.response.status;
    const detail = err.response && err.response.data ? JSON.stringify(err.response.data) : err.message;
    if (status === 402) {
      // Payment Required — the Arkesel account has no SMS credit left.
      logger.error(
        `[sms] Arkesel balance exhausted (402) sending to ${recipient} — top up at sms.arkesel.com. ${detail}`
      );
      return { ok: false, error: 'sms_balance_exhausted' };
    }
    logger.error(`[sms] failed to ${recipient} (${status || 'no response'}): ${detail}`);
    return { ok: false, error: err.message };
  }
}

module.exports = { sendSms, normalizePhone };
