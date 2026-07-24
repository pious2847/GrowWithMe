const axios = require('axios');
const env = require('../config/env');
const logger = require('../utils/logger');

const configured = () => Boolean(env.elevenlabs.apiKey);

/**
 * Natural-voice TTS via ElevenLabs (free tier). Returns an MP3 buffer.
 * The app falls back to on-device TTS whenever this is unavailable, so
 * failures here are soft.
 */
async function synthesize(text) {
  const url = `https://api.elevenlabs.io/v1/text-to-speech/${env.elevenlabs.voiceId}`;
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
}

module.exports = { synthesize, configured };
