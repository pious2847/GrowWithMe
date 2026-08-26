const axios = require('axios');
const env = require('../config/env');
const logger = require('../utils/logger');

const QUOTA_COOLDOWN_MS = 10 * 60 * 1000;
const quotaBlocks = {
  elevenlabs: 0,
  fish_audio: 0,
};

const getActiveProvider = (provider) => {
  return provider || env.voiceProvider;
};

const configured = (provider) => {
  const active = getActiveProvider(provider);
  if (active === 'fish_audio') {
    return Boolean(env.fishaudio.apiKey);
  }
  return Boolean(env.elevenlabs.apiKey);
};

const quotaBlocked = (provider) => {
  const active = getActiveProvider(provider);
  return Date.now() < (quotaBlocks[active] || 0);
};

const blockQuota = (provider) => {
  const active = getActiveProvider(provider);
  quotaBlocks[active] = Date.now() + QUOTA_COOLDOWN_MS;
};

/**
 * Natural-voice TTS via ElevenLabs. Returns an MP3 buffer.
 */
async function synthesizeElevenLabs(text) {
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
    logger.info(`[voice-elevenlabs] synthesized ${text.length} chars`);
    return Buffer.from(res.data);
  } catch (err) {
    const status = err.response && err.response.status;
    if (status === 402 || status === 401 || status === 429) {
      blockQuota('elevenlabs');
      logger.error(
        `[voice-elevenlabs] ElevenLabs quota/credits exhausted (${status}) — top up at elevenlabs.io. ` +
          `Pausing natural voice for ${QUOTA_COOLDOWN_MS / 60000} min; apps use device TTS meanwhile.`
      );
    } else {
      logger.error(`[voice-elevenlabs] synthesis failed (${status || err.message})`);
    }
    throw err;
  }
}

/**
 * Natural-voice TTS via Fish Audio. Returns an MP3 buffer.
 */
async function synthesizeFishAudio(text) {
  const url = 'https://api.fish.audio/v1/tts';
  try {
    const res = await axios.post(
      url,
      {
        text,
        reference_id: env.fishaudio.voiceId,
        format: 'mp3',
      },
      {
        headers: {
          Authorization: `Bearer ${env.fishaudio.apiKey}`,
          'Content-Type': 'application/json',
          Accept: 'audio/mpeg',
          model: env.fishaudio.model,
        },
        responseType: 'arraybuffer',
        timeout: 30000,
      }
    );
    logger.info(`[voice-fishaudio] synthesized ${text.length} chars`);
    return Buffer.from(res.data);
  } catch (err) {
    const status = err.response && err.response.status;
    if (status === 402 || status === 401 || status === 429) {
      blockQuota('fish_audio');
      logger.error(
        `[voice-fishaudio] Fish Audio quota/credits exhausted (${status}) — top up at fish.audio. ` +
          `Pausing natural voice for ${QUOTA_COOLDOWN_MS / 60000} min; apps use device TTS meanwhile.`
      );
    } else {
      logger.error(`[voice-fishaudio] synthesis failed (${status || err.message})`);
    }
    throw err;
  }
}

/**
 * Synthesize voice based on selected provider.
 */
async function synthesize(text, provider = null) {
  const active = getActiveProvider(provider);
  if (active === 'fish_audio') {
    return synthesizeFishAudio(text);
  }
  return synthesizeElevenLabs(text);
}

module.exports = { synthesize, configured, quotaBlocked };
