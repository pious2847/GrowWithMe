const cron = require('node-cron');
const Reminder = require('../models/Reminder');
const { sendSms } = require('./arkesel');
const logger = require('../utils/logger');

// SMS fallback for the care calendar: once a day, remind caregivers whose
// visits are due within the next 24h and mark long-overdue reminders missed
// so facility dashboards can flag them.
async function processDueReminders() {
  const now = new Date();
  const dayAhead = new Date(now.getTime() + 24 * 60 * 60 * 1000);

  const due = await Reminder.find({
    deleted: false,
    status: 'upcoming',
    dueDate: { $lte: dayAhead },
    smsSentAt: null,
  })
    .populate('owner', 'phone name consent')
    .limit(500);

  for (const reminder of due) {
    const owner = reminder.owner;
    if (!owner || !owner.phone || (owner.consent && owner.consent.smsReminders === false)) continue;
    const when = reminder.dueDate <= now ? 'today' : 'tomorrow';
    const res = await sendSms(
      owner.phone,
      `Reminder: ${reminder.title} is due ${when}. Please visit your nearest CHPS compound or clinic. - GrowWithMe`
    );
    if (res.ok) {
      reminder.smsSentAt = new Date();
      await reminder.save();
    }
  }

  const graceDays = 7;
  const missedBefore = new Date(now.getTime() - graceDays * 24 * 60 * 60 * 1000);
  await Reminder.updateMany(
    { deleted: false, status: 'upcoming', dueDate: { $lt: missedBefore } },
    { $set: { status: 'missed' } }
  );
}

function startReminderScheduler() {
  // Every day at 08:00 server time
  cron.schedule('0 8 * * *', () => {
    logger.info('[reminders] daily run starting');
    processDueReminders().catch((err) => logger.error('[reminders] run failed:', err));
  });
  logger.info('[reminders] scheduler started (daily 08:00)');
}

module.exports = { startReminderScheduler, processDueReminders };
