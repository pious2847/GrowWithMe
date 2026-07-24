const axios = require('axios');
const env = require('../config/env');
const logger = require('../utils/logger');

const NIM_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';

// Nana: the AI care educator. She teaches and helps operate the app — she
// NEVER diagnoses or classifies risk; the deterministic triage engine owns
// that. Any mention of danger signs → she directs to the in-app health check.
const SYSTEM_PROMPT = `You are Nana, a warm, wise Ghanaian grandmother who helps mothers and caregivers in Northern Ghana use the GrowWithMe app and care for their children (0-59 months) and pregnancies.

STYLE:
- Very short sentences. Simple English a low-literacy caregiver understands when read aloud.
- Warm, encouraging, respectful. You may use "my daughter" or "well done".
- Prefer foods and examples from Northern Ghana (TZ, koko, groundnut, moringa, dawadawa, ayoyo).

SAFETY RULES (never break these):
- You NEVER diagnose illness or judge how serious symptoms are.
- If the user mentions ANY symptom or danger sign (fever, fits, bleeding, vomiting, weakness, baby not moving...), respond with care and IMMEDIATELY use the start_health_check action so the app's safe checker takes over.
- Never discourage going to a clinic. When in doubt, advise going.
- Do not invent medical doses or medicines.

ACTIONS you can perform for the user (the app executes them after the user confirms). When you have gathered every required parameter, output the action. If parameters are missing, ask ONE short question at a time.
- add_child: {"name": string, "sex": "male"|"female", "dateOfBirth": "YYYY-MM-DD"}
- add_pregnancy: {"expectedDueDate": "YYYY-MM-DD"} (or ask for first day of last period and add 280 days yourself)
- log_weight: {"childName": string, "weightKg": number}
- start_health_check: {"subject": "child"|"pregnancy", "childName": string (only for child)}
- read_today: {} (the app reads today's visits and tip aloud)
- plan_diet: {} (opens the meal planner — use whenever she asks about food, meals, diet, what to eat, or affording food)
- set_reminder: {"title": string, "date": "YYYY-MM-DD", "time": "HH:MM"} (24-hour time. Use when she asks to be reminded of something. If she gave no time, ask ONE short question for it; if she says any time or does not mind, use "09:00". Compute dates like "next Tuesday" from today's date in the context.)

RESPONSE FORMAT — always reply with ONLY a JSON object, no other text:
{"say": "<what you tell the user, spoken aloud>", "action": null | {"name": "<action name>", "params": {...}}}

CONTEXT about this user is provided in the first user message. Today's date is given there too — use it to compute dates of birth from ages.`;

const configured = () => Boolean(env.nvidia.apiKey);

/**
 * One chat turn with Nana. `messages` is the running [{role, content}] history
 * from the app (user/assistant only); `context` is a compact summary of the
 * caregiver's data the app builds locally.
 * Returns { say, action } — always safe-parsed.
 */
async function chat(messages, context) {
  const payload = {
    model: env.nvidia.model,
    temperature: 0.4,
    max_tokens: 400,
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: `CONTEXT (not written by the user):\n${context}` },
      { role: 'assistant', content: '{"say": "I understand. I am ready to help.", "action": null}' },
      ...messages.slice(-12),
    ],
  };

  const res = await axios.post(NIM_URL, payload, {
    headers: {
      Authorization: `Bearer ${env.nvidia.apiKey}`,
      'Content-Type': 'application/json',
    },
    // The free NIM endpoint can queue under load — allow a generous window.
    timeout: 90000,
  });

  const raw = res.data?.choices?.[0]?.message?.content || '';
  return parseReply(raw);
}

function parseReply(raw) {
  // The model is asked for pure JSON, but be forgiving: find the outermost
  // object and fall back to treating the whole text as speech.
  try {
    const start = raw.indexOf('{');
    const end = raw.lastIndexOf('}');
    if (start !== -1 && end > start) {
      const parsed = JSON.parse(raw.slice(start, end + 1));
      if (typeof parsed.say === 'string') {
        return { say: parsed.say, action: parsed.action || null };
      }
    }
  } catch (err) {
    logger.warn('[nana] reply was not valid JSON, using as plain text');
  }
  return { say: raw.trim() || 'Sorry, I did not get that. Please try again.', action: null };
}

const CHECKIN_PROMPT = `You generate a short pregnancy check-in questionnaire for a mother in Northern Ghana, personalized from her history. Rules:
- 4 to 6 questions, each answerable YES or NO, in very simple English.
- Personalize: follow up on symptoms or risks from her history (e.g. if she reported headaches before, ask if they returned or worsened).
- Each question has a category:
  "danger"  = a YES means she needs a facility NOW (bleeding, fits, severe pain, no baby movement, water broken)
  "caution" = a YES means she should visit a clinic soon (swelling, tiredness, fever, poor sleep/appetite, worry)
  "info"    = wellbeing only (eating well, taking iron tablets, sleeping under a net)
- Never ask about medicines/doses. Never diagnose.
Reply with ONLY JSON: {"questions": [{"id": "q1", "text": "...", "category": "danger|caution|info"}]}`;

/**
 * Personalized pregnancy check-in questions from the caregiver's history.
 * The app ALWAYS merges these with its fixed deterministic danger-sign core —
 * the AI can add caution, never remove it.
 */
async function checkinQuestions(context) {
  const payload = {
    model: env.nvidia.model,
    temperature: 0.5,
    max_tokens: 500,
    messages: [
      { role: 'system', content: CHECKIN_PROMPT },
      { role: 'user', content: `HER HISTORY AND CURRENT DATA:\n${context}` },
    ],
  };
  const res = await axios.post(NIM_URL, payload, {
    headers: {
      Authorization: `Bearer ${env.nvidia.apiKey}`,
      'Content-Type': 'application/json',
    },
    timeout: 90000,
  });
  const raw = res.data?.choices?.[0]?.message?.content || '';
  const start = raw.indexOf('{');
  const end = raw.lastIndexOf('}');
  const parsed = JSON.parse(raw.slice(start, end + 1));
  const valid = (parsed.questions || [])
    .filter(
      (q) =>
        q &&
        typeof q.text === 'string' &&
        ['danger', 'caution', 'info'].includes(q.category)
    )
    .slice(0, 6)
    .map((q, i) => ({ id: q.id || `ai_q${i + 1}`, text: q.text, category: q.category }));
  return valid;
}

const DIET_PROMPT = `You are Nana, planning ONE day of meals for a mother in Northern Ghana. You will receive her stage (pregnant week / breastfeeding / child age), the current food season, and either structured answers OR her own spoken words (e.g. "money is small this week, I have maize and groundnut at home, we are five people").

If given her spoken words, EXTRACT from them: whether money is tight ("low") or she can buy extras ("ok"), the foodstuffs she has, and how many people eat together. If something is not mentioned, assume: budget low, household 4, pantry unknown.

RULES:
- Use ONLY affordable Northern Ghana foods. If she listed what she has, build mainly from those items, adding at most 1-2 cheap market items (e.g. one egg, small dried fish, groundnut paste).
- Portions in LOCAL measures: ladle, milk tin, handful, small bowl, one egg. Never grams.
- Very simple English. Short sentences that read well aloud.
- Cover her stage's priority: pregnancy = iron foods (green leaves, beans) + extra small meal; breastfeeding = extra food + plenty fluids; young child = thick enriched porridge, mashed family food.
- Simple preparation steps (2-3 short steps), balancing with minimal resources.
- Never mention supplements/medicines except "take your iron tablets" for pregnancy.

For EACH meal time give TWO different options so she can choose — both must fit her foods and budget, and be genuinely different dishes (not the same dish reworded). Every option must be an actual FOOD or DRINK she can prepare — never advice, tablets or reminders (those belong in "tips").

Reply with ONLY JSON:
{"summary": "<1-2 warm sentences>", "meals": [{"time": "Morning|Midday|Evening|Snack", "options": [{"name": "...", "ingredients": "...", "portion": "...", "prep": "..."}, {"name": "...", "ingredients": "...", "portion": "...", "prep": "..."}]}], "tips": ["...", "..."], "extracted": {"budget": "low"|"ok", "pantry": "<foodstuffs she has, comma separated>", "household": "<number as string>"}}`;

function parseDietJson(raw) {
  const sliced = raw.slice(raw.indexOf('{'), raw.lastIndexOf('}') + 1);
  let parsed;
  try {
    parsed = JSON.parse(sliced);
  } catch (_) {
    // Small models sometimes emit trailing commas — repair and retry.
    parsed = JSON.parse(sliced.replace(/,\s*([}\]])/g, '$1'));
  }
  if (!parsed.summary || !Array.isArray(parsed.meals)) {
    throw new Error('malformed diet plan');
  }
  // Normalize: each slot carries up to 2 options; tolerate the old
  // single-meal shape by wrapping it as one option.
  parsed.meals = parsed.meals.slice(0, 5).map((slot) => ({
    time: slot.time || 'Meal',
    options: (Array.isArray(slot.options) ? slot.options : [slot])
      .filter((o) => o && o.name)
      .slice(0, 2),
  })).filter((slot) => slot.options.length > 0);
  parsed.tips = (parsed.tips || []).slice(0, 4);
  return parsed;
}

/** One-day personalized meal plan. Returns the parsed plan object.
 * Two attempts: small free models occasionally truncate or malform JSON. */
async function dietPlan(context) {
  const payload = {
    model: env.nvidia.model,
    temperature: 0.5,
    // Two options per meal slot roughly doubles the output — size for it,
    // or the JSON gets cut off mid-array.
    max_tokens: 1600,
    messages: [
      { role: 'system', content: DIET_PROMPT },
      { role: 'user', content: `HER SITUATION:\n${context}` },
    ],
  };
  let lastError;
  for (let attempt = 1; attempt <= 2; attempt++) {
    try {
      const res = await axios.post(NIM_URL, payload, {
        headers: {
          Authorization: `Bearer ${env.nvidia.apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 90000,
      });
      const raw = res.data?.choices?.[0]?.message?.content || '';
      return parseDietJson(raw);
    } catch (err) {
      lastError = err;
      logger.warn(`[nana] diet plan attempt ${attempt} failed: ${err.message}`);
    }
  }
  throw lastError;
}

module.exports = { chat, checkinQuestions, dietPlan, configured };
