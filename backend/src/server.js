const env = require('./config/env');
const app = require('./app');
const { connectDB } = require('./config/db');
const { startReminderScheduler } = require('./services/reminderScheduler');
const { startCareSignalScan } = require('./services/careSignalScan');
const logger = require('./utils/logger');

async function main() {
  await connectDB();
  startReminderScheduler();
  startCareSignalScan();
  app.listen(env.port, () => {
    logger.info(`[server] GrowWithMe backend listening on http://localhost:${env.port} (${env.nodeEnv})`);
    logger.info(`[server] request log file: ${logger.LOG_FILE}`);
  });
}

main().catch((err) => {
  logger.error('[server] failed to start:', err);
  process.exit(1);
});
