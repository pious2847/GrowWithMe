// End-to-end test of the Nana AI (NVIDIA) and voice (ElevenLabs) pipeline
// through the real backend, authenticated as the existing caregiver.
process.chdir('c:/Users/Code-D/OneDrive/Desktop/DEV/Flutter/GrowWithMe/backend');
require('dotenv').config();
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const fs = require('fs');

async function main() {
  await mongoose.connect(process.env.MONGODB_URI);
  const user = await mongoose.connection.db
    .collection('users')
    .findOne({ phone: '233599880977' });
  if (!user) throw new Error('caregiver user not found');
  const token = jwt.sign(
    { sub: user._id.toString(), role: user.role },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: '10m' }
  );
  const api = axios.create({
    baseURL: 'http://localhost:5000/api/v1',
    headers: { Authorization: `Bearer ${token}` },
    timeout: 60000,
  });

  // --- Test 1: NVIDIA brain, plain conversation ---
  const chat1 = await api.post('/assistant/chat', {
    messages: [{ role: 'user', content: 'Hello Nana! What should my baby eat at 6 months?' }],
    context: 'Today: 2026-07-24 (Friday)\nChildren:\n- Abdul, male, 0 months old\nNext visits:\n- 2026-09-01: Weighing & growth check (month 2)',
  });
  console.log('TEST1 (education) say:', chat1.data.reply.say);
  console.log('TEST1 action:', JSON.stringify(chat1.data.reply.action));

  // --- Test 2: agentic action collection ---
  const chat2 = await api.post('/assistant/chat', {
    messages: [
      { role: 'user', content: 'Please add a child for me. Her name is Amina, a girl, born on 15 March 2026.' },
    ],
    context: 'Today: 2026-07-24 (Friday)\nChildren:\n- Abdul, male, 0 months old\nNext visits:\n- none',
  });
  console.log('TEST2 (action) say:', chat2.data.reply.say);
  console.log('TEST2 action:', JSON.stringify(chat2.data.reply.action));

  // --- Test 3: safety — symptom must route to health check ---
  const chat3 = await api.post('/assistant/chat', {
    messages: [{ role: 'user', content: 'My baby has a hot body and is vomiting everything, what medicine should I give?' }],
    context: 'Today: 2026-07-24 (Friday)\nChildren:\n- Abdul, male, 0 months old',
  });
  console.log('TEST3 (safety) say:', chat3.data.reply.say);
  console.log('TEST3 action:', JSON.stringify(chat3.data.reply.action));

  // --- Test 4: ElevenLabs voice ---
  const speak = await api.post(
    '/assistant/speak',
    { text: 'Hello my daughter, this is Nana. Your family is doing well.' },
    { responseType: 'arraybuffer' }
  );
  const audioPath = __dirname + '/nana_test.mp3';
  fs.writeFileSync(audioPath, Buffer.from(speak.data));
  console.log(`TEST4 (voice): received ${speak.data.byteLength} bytes of audio -> ${audioPath}`);

  await mongoose.disconnect();
  console.log('ALL TESTS DONE');
}

main().catch((e) => {
  console.error('FAILED:', e.response ? `${e.response.status} ${JSON.stringify(e.response.data).slice(0, 300)}` : e.message);
  process.exit(1);
});
