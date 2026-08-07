const axios = require('axios');
const env = require('../config/env');
const logger = require('../utils/logger');
const {
  FEEDING_KNOWLEDGE,
  PREGNANCY_DANGER_SIGNS,
  BABY_DANGER_SIGNS,
  PROTECTING_PREGNANCY,
  LABOUR_AND_DELIVERY,
  CHILD_MILESTONES,
} = require('./nanaKnowledge');

const NIM_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';

// Nana: the AI care educator. She teaches and helps operate the app — she
// NEVER diagnoses or classifies risk; the deterministic triage engine owns
// that. Any mention of danger signs → she directs to the in-app health check.
const NIM_HEADERS = () => ({
  Authorization: `Bearer ${env.nvidia.apiKey}`,
  'Content-Type': 'application/json',
});

/**
 * One NIM call with completeness guarantees:
 * - guided_json (decoder-level schema constraint) when a schema is given,
 *   with automatic unguided fallback if the endpoint rejects it;
 * - finish_reason inspection: output cut by the token limit is NEVER parsed —
 *   the call retries with a doubled budget instead.
 */
async function callNim(payload, { schema } = {}) {
  let useGuided = Boolean(schema);
  let tokens = payload.max_tokens;
  for (let attempt = 0; attempt < 3; attempt++) {
    const body = { ...payload, max_tokens: tokens };
    if (useGuided) body.nvext = { guided_json: schema };
    try {
      const res = await axios.post(NIM_URL, body, {
        headers: NIM_HEADERS(),
        timeout: 90000,
      });
      const choice = res.data?.choices?.[0] || {};
      const content = choice.message?.content || '';
      if (choice.finish_reason === 'length') {
        logger.warn(
          `[nana] output hit the ${tokens}-token limit — retrying with ${tokens * 2}`
        );
        tokens *= 2;
        continue;
      }
      return content;
    } catch (err) {
      const status = err.response?.status;
      if (useGuided && status >= 400 && status < 500) {
        logger.warn('[nana] guided_json rejected by endpoint — retrying unguided');
        useGuided = false;
        continue;
      }
      throw err;
    }
  }
  throw new Error('model output kept exceeding the token limit');
}

const CHAT_SCHEMA = {
  type: 'object',
  properties: {
    say: { type: 'string' },
    action: {
      anyOf: [
        { type: 'null' },
        {
          type: 'object',
          properties: {
            name: { type: 'string' },
            params: { type: 'object' },
          },
          required: ['name', 'params'],
        },
      ],
    },
  },
  required: ['say', 'action'],
};

const CHECKIN_SCHEMA = {
  type: 'object',
  properties: {
    questions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          text: { type: 'string' },
          category: { type: 'string', enum: ['danger', 'caution', 'info'] },
        },
        required: ['text', 'category'],
      },
    },
  },
  required: ['questions'],
};

const MEAL_OPTION_SCHEMA = {
  type: 'object',
  properties: {
    name: { type: 'string' },
    ingredients: { type: 'string' },
    portion: { type: 'string' },
    prep: { type: 'string' },
  },
  required: ['name', 'ingredients', 'portion', 'prep'],
};

const DIET_SCHEMA = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    meals: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          time: { type: 'string' },
          options: { type: 'array', items: MEAL_OPTION_SCHEMA },
        },
        required: ['time', 'options'],
      },
    },
    tips: { type: 'array', items: { type: 'string' } },
    extracted: {
      type: 'object',
      properties: {
        budget: { type: 'string', enum: ['low', 'ok'] },
        pantry: { type: 'string' },
        household: { type: 'string' },
      },
    },
  },
  required: ['summary', 'meals'],
};

const TIPS_SCHEMA = {
  type: 'object',
  properties: {
    tips: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          audience: {
            type: 'string',
            enum: ['child', 'pregnancy', 'lactating', 'general'],
          },
          title: { type: 'string' },
          body: { type: 'string' },
        },
        required: ['audience', 'title', 'body'],
      },
    },
  },
  required: ['tips'],
};

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
- You are an AI helper, not a health worker, and you can make mistakes. Never claim certainty about health matters. When advice really matters (symptoms, medicines, feeding a sick child), remind her gently that the nurse or midwife at the clinic has the final word.

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

CONTEXT about this user is provided in the first user message. Today's date is given there too — use it to compute dates of birth from ages.

TRUSTED KNOWLEDGE — the official Ghana Health Service / WHO guidance used by health workers. Base every answer on it; never contradict it; do not invent guidance beyond it:
${FEEDING_KNOWLEDGE}
${PREGNANCY_DANGER_SIGNS}
${BABY_DANGER_SIGNS}
${PROTECTING_PREGNANCY}
${LABOUR_AND_DELIVERY}
${CHILD_MILESTONES}
If she mentions anything matching a danger sign above, use start_health_check. For milestones: if the child's age is AT or PAST a milestone age and the child cannot do it, warmly advise visiting the health facility now — do not tell her to wait. Same for any hearing or seeing warning sign.`;

const configured = () => Boolean(env.nvidia.apiKey);

/**
 * Closes whatever a truncated JSON string left open — unterminated string,
 * then every unclosed bracket/brace in the correct order.
 */
function balanceClose(s) {
  let inStr = false;
  let esc = false;
  const stack = [];
  for (const ch of s) {
    if (esc) {
      esc = false;
      continue;
    }
    if (inStr && ch === '\\') {
      esc = true;
      continue;
    }
    if (ch === '"') {
      inStr = !inStr;
      continue;
    }
    if (inStr) continue;
    if (ch === '{' || ch === '[') stack.push(ch);
    else if (ch === '}' || ch === ']') stack.pop();
  }
  let out = s;
  if (inStr) out += '"';
  out = out.replace(/,\s*$/, '');
  while (stack.length) out += stack.pop() === '{' ? '}' : ']';
  return out;
}

/**
 * Forgiving JSON parse for small-model output: tolerates trailing commas,
 * and truncation anywhere — mid-string, mid-array, mid-object. As a last
 * resort it cuts back to the last complete element and closes from there
 * (losing at most the partial trailing item).
 */
function parseJsonLoose(raw) {
  const start = raw.indexOf('{');
  if (start === -1) throw new Error('no JSON object found');
  const body = raw.slice(start).trim();

  const candidates = [];
  const toLastBrace = body.slice(0, body.lastIndexOf('}') + 1);
  if (toLastBrace) candidates.push(toLastBrace);
  candidates.push(balanceClose(body));
  // Cut back to progressively earlier complete elements, then close.
  let cut = body.length;
  for (let i = 0; i < 8; i++) {
    const lastCloser = Math.max(
      body.lastIndexOf('}', cut - 1),
      body.lastIndexOf(']', cut - 1)
    );
    if (lastCloser <= 0) break;
    candidates.push(balanceClose(body.slice(0, lastCloser + 1)));
    cut = lastCloser;
  }

  for (const base of candidates) {
    for (const s of [base, base.replace(/,\s*([}\]])/g, '$1')]) {
      try {
        return JSON.parse(s);
      } catch (_) {
        /* try next */
      }
    }
  }
  throw new Error('unparseable JSON');
}

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
    max_tokens: 700,
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: `CONTEXT (not written by the user):\n${context}` },
      { role: 'assistant', content: '{"say": "I understand. I am ready to help.", "action": null}' },
      ...messages.slice(-12),
    ],
  };

  const raw = await callNim(payload, { schema: CHAT_SCHEMA });
  return parseReply(raw);
}

function parseReply(raw) {
  // The model is asked for pure JSON — parse forgivingly (truncation,
  // trailing commas), and NEVER show raw JSON to the caregiver.
  try {
    const parsed = parseJsonLoose(raw);
    if (typeof parsed.say === 'string') {
      return { say: parsed.say, action: parsed.action || null };
    }
  } catch (_) {
    logger.warn('[nana] reply was not valid JSON, salvaging');
  }
  // Salvage just the spoken text if the object is beyond repair.
  const sayMatch = raw.match(/"say"\s*:\s*"((?:[^"\\]|\\.)*)"/);
  if (sayMatch) {
    return { say: sayMatch[1].replace(/\\"/g, '"'), action: null };
  }
  // If the text contains no JSON at all, it IS the speech.
  if (!raw.includes('{')) {
    return { say: raw.trim(), action: null };
  }
  return {
    say: 'Sorry, my daughter — say that again for me?',
    action: null,
  };
}

const CHECKIN_PROMPT = `You generate a short pregnancy check-in questionnaire for a mother in Northern Ghana, like the routine questions a nurse asks at an antenatal (ANC) visit — but personalized from HER data. You receive her gestational week, her past check-ins (with the exact questions she answered YES to), and her family/diet data. Rules:
- 4 to 6 questions, each answerable YES or NO, in very simple English that reads well aloud.
- FOLLOW UP FIRST: for each symptom she said YES to recently, ask if it is still there or worse (e.g. YES to tiredness last time -> "Are you still feeling very tired, or is it worse now?"). Repeating a topic across check-ins is good — that is how a nurse tracks a symptom.
- The app ALWAYS asks these core danger questions itself, so do NOT repeat them: bleeding, fits/severe headache, severe belly pain, water breaking, baby movement, fever, swelling.
- Then add routine ANC-style questions matched to her week:
  weeks 1-13: severe vomiting, able to eat and keep food down, very dizzy or weak
  weeks 14-27: taking iron tablets, sleeping under a mosquito net, attended her ANC visit
  weeks 28+: iron tablets, resting enough, transport plan ready for delivery, items ready for the baby
- Also cover wellbeing when relevant: eating well, sleeping well, worry/low mood, support at home.
- Each question has a category:
  "danger"  = a YES means she needs a facility NOW
  "caution" = a YES means she should visit a clinic soon (tiredness, poor sleep/appetite, dizziness, worry)
  "info"    = wellbeing/routine only (iron tablets, net, ANC visit, transport plan)
- Phrase questions so YES = the problem is present for danger/caution, and YES = the good thing is happening for info.
- Never ask about medicine doses. Never diagnose.
Draw danger/caution topics ONLY from this official Ghana Health Service danger-sign list (the app's core already covers bleeding, fits/severe headache, severe belly pain, water breaking, baby movement, fever, swelling — use the OTHERS):
${PREGNANCY_DANGER_SIGNS}
${PROTECTING_PREGNANCY}
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
  const raw = await callNim(payload, { schema: CHECKIN_SCHEMA });
  const parsed = parseJsonLoose(raw);
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

GROUND EVERY PLAN IN THIS OFFICIAL GUIDANCE (Ghana Health Service / WHO — never contradict it):
${FEEDING_KNOWLEDGE}
For a child, match meal count, portion (tablespoons / fraction of a 250 ml cup) and texture to the child's exact age band above, and make the day cover all 4 star groups. For pregnancy, include iron-rich foods (green leaves, beans) daily.

Keep every field SHORT so nothing gets cut off: "prep" at most 2 short sentences, "ingredients" under 12 words, at most 4 meal times, at most 2 tips.

Reply with ONLY JSON:
{"summary": "<1-2 warm sentences>", "meals": [{"time": "Morning|Midday|Evening|Snack", "options": [{"name": "...", "ingredients": "...", "portion": "...", "prep": "..."}, {"name": "...", "ingredients": "...", "portion": "...", "prep": "..."}]}], "tips": ["...", "..."], "extracted": {"budget": "low"|"ok", "pantry": "<foodstuffs she has, comma separated>", "household": "<number as string>"}}`;

function parseDietJson(raw) {
  const parsed = parseJsonLoose(raw);
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
      const raw = await callNim(payload, { schema: DIET_SCHEMA });
      return parseDietJson(raw);
    } catch (err) {
      lastError = err;
      logger.warn(`[nana] diet plan attempt ${attempt} failed: ${err.message}`);
    }
  }
  throw lastError;
}

const TIP_PROMPT = `You are Nana, writing today's fresh feeding/nutrition tip(s) for a caregiver in Northern Ghana. You receive her situation: children and their ages, pregnancy stage, the food season, her recent diet scores, and the titles of tips she was shown recently.

RULES:
- Write ONE tip per relevant audience (child / pregnancy / lactating). Max 2 tips.
- Very short: a punchy title (3-6 words) and a body of 2-3 simple sentences a low-literacy caregiver understands when read aloud.
- Practical and specific to Northern Ghana foods and this season. Vary the topic — do NOT repeat any recent tip title.
- If her diet scores show missing food groups, target one of the gaps.
- Never mention medicines except "iron tablets" for pregnancy.
- Ground every tip in this official guidance (never contradict it):
${FEEDING_KNOWLEDGE}
${PROTECTING_PREGNANCY}

Reply with ONLY JSON:
{"tips": [{"audience": "child"|"pregnancy"|"lactating", "title": "...", "body": "..."}]}`;

/** Fresh personalized daily tips. Returns validated [{audience,title,body}]. */
async function dailyTips(context) {
  const payload = {
    model: env.nvidia.model,
    temperature: 0.7,
    max_tokens: 400,
    messages: [
      { role: 'system', content: TIP_PROMPT },
      { role: 'user', content: `HER SITUATION:\n${context}` },
    ],
  };
  const raw = await callNim(payload, { schema: TIPS_SCHEMA });
  const parsed = parseJsonLoose(raw);
  return (parsed.tips || [])
    .filter(
      (t) =>
        t &&
        typeof t.title === 'string' &&
        typeof t.body === 'string' &&
        ['child', 'pregnancy', 'lactating', 'general'].includes(t.audience)
    )
    .slice(0, 2);
}

module.exports = {
  chat,
  checkinQuestions,
  dietPlan,
  dailyTips,
  configured,
  parseJsonLoose,
};
