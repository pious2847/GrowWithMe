const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const env = require('../config/env');
const Otp = require('../models/Otp');
const User = require('../models/User');
const { sendSms, normalizePhone } = require('../services/arkesel');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../utils/jwt');
const logger = require('../utils/logger');

const MAX_OTP_ATTEMPTS = 5;

function issueTokens(user) {
  return {
    accessToken: signAccessToken(user),
    refreshToken: signRefreshToken(user),
  };
}

// POST /api/v1/auth/request-otp { phone }
const requestOtp = asyncHandler(async (req, res) => {
  const { phone } = req.body;
  if (!phone || !/^\+?\d[\d\s-]{7,14}$/.test(String(phone))) {
    throw ApiError.badRequest('A valid phone number is required');
  }
  const normalized = normalizePhone(phone);

  const code = crypto.randomInt(100000, 1000000).toString();
  const codeHash = await bcrypt.hash(code, 10);
  const expiresAt = new Date(Date.now() + env.otpTtlMinutes * 60 * 1000);

  await Otp.deleteMany({ phone: normalized });
  await Otp.create({ phone: normalized, codeHash, expiresAt });

  logger.info(`[auth] OTP requested for ${normalized}`);
  const result = await sendSms(
    normalized,
    `Your GrowWithMe verification code is ${code}. It expires in ${env.otpTtlMinutes} minutes.`
  );
  if (!result.ok) throw new ApiError(502, 'Could not send verification SMS. Please try again.');

  res.json({ success: true, message: 'OTP sent', expiresInMinutes: env.otpTtlMinutes });
});

// POST /api/v1/auth/verify-otp { phone, code, name?, language?, role? }
// Verifies the code; creates the user on first login (role is always caregiver
// on self-signup — volunteer/facility accounts are provisioned by an admin).
const verifyOtp = asyncHandler(async (req, res) => {
  const { phone, code } = req.body;
  if (!phone || !code) throw ApiError.badRequest('phone and code are required');
  const normalized = normalizePhone(phone);

  const otp = await Otp.findOne({ phone: normalized });
  if (!otp || otp.expiresAt < new Date()) {
    throw ApiError.unauthorized('Code expired. Please request a new one.');
  }
  if (otp.attempts >= MAX_OTP_ATTEMPTS) {
    await otp.deleteOne();
    throw ApiError.unauthorized('Too many attempts. Please request a new code.');
  }

  const match = await bcrypt.compare(String(code), otp.codeHash);
  if (!match) {
    otp.attempts += 1;
    await otp.save();
    throw ApiError.unauthorized('Incorrect code');
  }
  await otp.deleteOne();

  let user = await User.findOne({ phone: normalized });
  let isNew = false;
  if (!user) {
    isNew = true;
    user = await User.create({
      phone: normalized,
      name: req.body.name,
      language: req.body.language || 'en',
      role: 'caregiver',
    });
  }

  logger.info(`[auth] ${isNew ? 'new user registered' : 'login'}: ${normalized} role=${user.role}`);
  res.json({ success: true, isNewUser: isNew, user, tokens: issueTokens(user) });
});

// POST /api/v1/auth/refresh { refreshToken }
const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) throw ApiError.badRequest('refreshToken is required');
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw ApiError.unauthorized('Invalid or expired refresh token');
  }
  const user = await User.findById(payload.sub);
  if (!user) throw ApiError.unauthorized('User no longer exists');
  res.json({ success: true, tokens: issueTokens(user) });
});

module.exports = { requestOtp, verifyOtp, refresh };
