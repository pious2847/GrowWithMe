const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const nana = require('../services/nanaService');
const voice = require('../services/voiceService');
const logger = require('../utils/logger');

// POST /api/v1/assistant/chat { messages: [{role, content}], context: string }
// The app builds `context` locally (children, ages, today's visits) so the
// assistant works on the caregiver's real data without extra queries.
const chat = asyncHandler(async (req, res) => {
  if (!nana.configured()) {
    throw new ApiError(503, 'Assistant is not configured on this server (NVIDIA_API_KEY missing)');
  }
  const { messages = [], context = '' } = req.body || {};
  if (!Array.isArray(messages) || messages.length === 0) {
    throw ApiError.badRequest('messages array is required');
  }
  const safeMessages = messages
    .filter((m) => m && ['user', 'assistant'].includes(m.role) && typeof m.content === 'string')
    .map((m) => ({ role: m.role, content: m.content.slice(0, 2000) }));

  const reply = await nana.chat(safeMessages, String(context).slice(0, 4000));
  logger.info(
    `[nana] user=${req.user.phone} action=${reply.action ? reply.action.name : 'none'}`
  );
  res.json({ success: true, reply });
});

// POST /api/v1/assistant/speak { text } -> audio/mpeg
const speak = asyncHandler(async (req, res) => {
  if (!voice.configured()) {
    throw new ApiError(503, 'Voice is not configured on this server (ELEVENLABS_API_KEY missing)');
  }
  const { text } = req.body || {};
  if (!text || typeof text !== 'string') throw ApiError.badRequest('text is required');

  const audio = await voice.synthesize(text.slice(0, 900));
  res.set('Content-Type', 'audio/mpeg');
  res.send(audio);
});

// POST /api/v1/assistant/checkin-questions { context }
// AI-personalized pregnancy check-in questions from the caregiver's history.
// The app merges them with its fixed danger-sign core before use.
const checkinQuestions = asyncHandler(async (req, res) => {
  if (!nana.configured()) {
    throw new ApiError(503, 'Assistant is not configured on this server');
  }
  const context = String(req.body?.context || '').slice(0, 4000);
  const questions = await nana.checkinQuestions(context);
  logger.info(`[nana] check-in questions generated for ${req.user.phone}: ${questions.length}`);
  res.json({ success: true, questions });
});

// POST /api/v1/assistant/diet-plan { context }
const dietPlan = asyncHandler(async (req, res) => {
  if (!nana.configured()) {
    throw new ApiError(503, 'Assistant is not configured on this server');
  }
  const context = String(req.body?.context || '').slice(0, 4000);
  const plan = await nana.dietPlan(context);
  logger.info(`[nana] diet plan generated for ${req.user.phone} (${plan.meals.length} meals)`);
  res.json({ success: true, plan });
});

// POST /api/v1/assistant/daily-tips { context }
const dailyTips = asyncHandler(async (req, res) => {
  if (!nana.configured()) {
    throw new ApiError(503, 'Assistant is not configured on this server');
  }
  const context = String(req.body?.context || '').slice(0, 4000);
  const tips = await nana.dailyTips(context);
  logger.info(`[nana] daily tips generated for ${req.user.phone}: ${tips.length}`);
  res.json({ success: true, tips });
});

module.exports = { chat, speak, checkinQuestions, dietPlan, dailyTips };
