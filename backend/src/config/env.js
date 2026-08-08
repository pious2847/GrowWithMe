require('dotenv').config();

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '5000', 10),
  mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/growwithme',
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET || 'dev-access-secret',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret',
    accessExpires: process.env.JWT_ACCESS_EXPIRES || '7d',
    refreshExpires: process.env.JWT_REFRESH_EXPIRES || '60d',
  },
  arkesel: {
    apiKey: process.env.ARKESEL_API_KEY || '',
    senderId: process.env.ARKESEL_SENDER_ID || 'GrowWithMe',
  },
  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME || '',
    apiKey: process.env.CLOUDINARY_API_KEY || '',
    apiSecret: process.env.CLOUDINARY_API_SECRET || '',
  },
  nvidia: {
    apiKey: process.env.NVIDIA_API_KEY || '',
    model: process.env.NVIDIA_MODEL || 'meta/llama-3.1-70b-instruct',
  },
  elevenlabs: {
    apiKey: process.env.ELEVENLABS_API_KEY || '',
    // Default: Sarah — a premade voice, usable on free-tier API keys.
    // (Library/community voices and legacy Rachel 402 on free accounts.)
    voiceId: process.env.ELEVENLABS_VOICE_ID || 'EXAVITQu4vr4xnSDxMaL',
  },
  otpTtlMinutes: parseInt(process.env.OTP_TTL_MINUTES || '10', 10),
  // OTP_DEBUG=true: when SMS sending fails, log the code server-side and let
  // the flow continue — demo/dev safety net only, never for real production.
  otpDebug: process.env.OTP_DEBUG === 'true',
  // Public base URL for links that travel by SMS (alert deep links)
  publicUrl: process.env.PUBLIC_URL || 'https://growwithme.onrender.com',
  isProd: (process.env.NODE_ENV || 'development') === 'production',
};

if (env.isProd) {
  const required = ['JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET', 'MONGODB_URI', 'ARKESEL_API_KEY'];
  const missing = required.filter((k) => !process.env[k]);
  if (missing.length) {
    throw new Error(`Missing required env vars in production: ${missing.join(', ')}`);
  }
}

module.exports = env;
