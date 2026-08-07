const mongoose = require('mongoose');
const env = require('./env');
const logger = require('../utils/logger');

/** Documents with malformed geo data (empty/partial coordinates) block
 * 2dsphere index builds with "Can't extract geo keys" — strip the bad field
 * so the index can build and $near queries work. */
async function cleanInvalidGeo(collectionName) {
  try {
    const res = await mongoose.connection.db.collection(collectionName).updateMany(
      {
        location: { $exists: true },
        $or: [
          { 'location.type': { $ne: 'Point' } },
          { 'location.coordinates.1': { $exists: false } },
        ],
      },
      { $unset: { location: '' } }
    );
    if (res.modifiedCount > 0) {
      logger.warn(`[db] ${collectionName}: removed malformed location from ${res.modifiedCount} doc(s)`);
    }
  } catch (err) {
    logger.error(`[db] geo cleanup failed for ${collectionName}: ${err.message}`);
  }
}

async function connectDB() {
  mongoose.set('strictQuery', true);
  await mongoose.connect(env.mongoUri);
  logger.info(`[db] connected to ${mongoose.connection.name}`);

  // Mongoose's background autoIndex swallows failures silently — a bad
  // document can leave a geo index missing with no trace, and every $near
  // query then 500s. Build indexes explicitly and LOUDLY instead.
  await cleanInvalidGeo('alerts');
  await cleanInvalidGeo('users');
  for (const name of mongoose.modelNames()) {
    try {
      await mongoose.model(name).createIndexes();
    } catch (err) {
      logger.error(`[db] index build failed for ${name}: ${err.message}`);
    }
  }
  logger.info('[db] indexes ensured');
}

module.exports = { connectDB };
