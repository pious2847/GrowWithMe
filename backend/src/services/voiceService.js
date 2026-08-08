const axios = require('axios');
const env = require('../config/env');
const logger = require('../utils/logger');

const configured = () => Boolean(env.elevenlabs.apiKey);

// When ElevenLabs says the quota is gone (402/401/429), stop calling it for a
// while — every request otherwise wastes seconds re-failing, and the app's
// device-TTS fallback takes over anyway.
const QUOTA_COOLDOWN_MS = 10 * 60 * 1000;
let quotaBlockedUntil = 0;

const quotaBlocked = () => Date.now() < quotaBlockedUntil;

/**
 * Natural-voice TTS via ElevenLabs (free tier). Returns an MP3 buffer.
 * The app falls back to on-device TTS whenever this is unavailable, so
 * failures here are soft.
 */
async function synthesize(text) {
  const url = `https://api.elevenlabs.io/v1/text-to-speech/${env.elevenlabs.voiceId}`;
  try {
    const res = await axios.post(
      url,
      {
        text,
        model_id: 'eleven_turbo_v2_5',
        voice_settings: { stability: 0.5, similarity_boost: 0.7 },
      },
      {
        headers: {
          'xi-api-key': env.elevenlabs.apiKey,
          'Content-Type': 'application/json',
          Accept: 'audio/mpeg',
        },
        responseType: 'arraybuffer',
        timeout: 30000,
      }
    );
    logger.info(`[voice] synthesized ${text.length} chars`);
    return Buffer.from(res.data);
  } catch (err) {
    const status = err.response && err.response.status;
    if (status === 402 || status === 401 || status === 429) {
      quotaBlockedUntil = Date.now() + QUOTA_COOLDOWN_MS;
      logger.error(
        `[voice] ElevenLabs quota/credits exhausted (${status}) — top up at elevenlabs.io. ` +
          `Pausing natural voice for ${QUOTA_COOLDOWN_MS / 60000} min; apps use device TTS meanwhile.`
      );
    } else {
      logger.error(`[voice] synthesis failed (${status || err.message})`);
    }
    throw err;
  }
}

module.exports = { synthesize, configured, quotaBlocked };
