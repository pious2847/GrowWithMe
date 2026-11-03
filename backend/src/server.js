const mongoose = require('mongoose');
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
  const server = app.listen(env.port, () => {
    logger.info(`[server] GrowWithMe backend listening on http://localhost:${env.port} (${env.nodeEnv})`);
    logger.info(`[server] request log file: ${logger.LOG_FILE}`);
  });

  // Deploys (Render, Docker, systemd) send SIGTERM. Stop accepting requests,
  // drain in-flight ones, then close Mongo — no half-processed OTP or sync.
  let shuttingDown = false;
  async function shutdown(signal) {
    if (shuttingDown) return;
    shuttingDown = true;
    logger.info(`[server] ${signal} received — shutting down gracefully`);
    const force = setTimeout(() => {
      logger.error('[server] shutdown timed out; exiting');
      process.exit(1);
    }, 10_000);
    force.unref();

    server.close(async () => {
      try {
        await mongoose.disconnect();
        logger.info('[server] closed cleanly');
        process.exit(0);
      } catch (err) {
        logger.error('[server] error while closing:', err);
        process.exit(1);
      }
    });
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  logger.error('[server] failed to start:', err);
  process.exit(1);
});
