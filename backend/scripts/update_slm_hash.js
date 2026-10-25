/**
 * Updates the nana-slm model hash in the database
 * Usage: node scripts/update_slm_hash.js <sha256> <sizeBytes> [--env atlas-credentials.env]
 */
const path = require('path');

const envFile = process.argv.includes('--env')
  ? process.argv[process.argv.indexOf('--env') + 1]
  : '.env';
require('dotenv').config({ path: path.join(__dirname, '..', envFile) });

require('dns').setServers(['8.8.8.8', '1.1.1.1']);

const mongoose = require('mongoose');
const MlModel = require('../src/models/MlModel');

const MODEL_NAME = 'nana-slm';

async function updateHash(dbUri, sha256, sizeBytes) {
  const isAtlas = dbUri.includes('mongodb+srv');
  console.log(`\nConnecting to ${isAtlas ? 'MongoDB Atlas' : 'Local MongoDB'}...`);

  const conn = await mongoose.createConnection(dbUri).asPromise();

  try {
    const Model = conn.model('MlModel', MlModel.schema);

    const doc = await Model.findOneAndUpdate(
      { name: MODEL_NAME },
      {
        $set: {
          sha256,
          sizeBytes,
          updatedAt: new Date(),
        },
      },
      { new: true }
    );

    if (!doc) {
      console.log(`✗ Model '${MODEL_NAME}' not found in database`);
      return false;
    }

    console.log(`✓ Updated ${MODEL_NAME} in ${isAtlas ? 'MongoDB Atlas' : 'Local MongoDB'}`);
    console.log(`  Version: ${doc.version}`);
    console.log(`  SHA256: ${doc.sha256}`);
    console.log(`  Size: ${(doc.sizeBytes / 1024 / 1024).toFixed(2)} MB`);
    return true;
  } finally {
    await conn.close();
  }
}

async function main() {
  const sha256 = process.argv[2];
  const sizeBytes = parseInt(process.argv[3]);

  if (!sha256 || !sizeBytes) {
    console.error('Usage: node scripts/update_slm_hash.js <sha256> <sizeBytes>');
    console.error('Example: node scripts/update_slm_hash.js "d8996679c3b439ec9a446bb3b3dc0650017973882328ae51c769c8f891e6540f" 11379577');
    process.exit(1);
  }

  console.log('==============================================');
  console.log(' Update Nana SLM Hash');
  console.log('==============================================');
  console.log(`\nNew SHA256: ${sha256}`);
  console.log(`New Size: ${(sizeBytes / 1024 / 1024).toFixed(2)} MB`);

  try {
    // Update Local MongoDB
    const localDbUri = process.env.MONGO_URI || process.env.MONGODB_URI;
    if (localDbUri) {
      console.log('\n----------------------------------------------');
      console.log('Updating Local MongoDB');
      console.log('----------------------------------------------');
      await updateHash(localDbUri, sha256, sizeBytes);
    }

    // Update MongoDB Atlas
    const remoteDbUri = process.env.MONGODB_ATLAS_URI;
    if (remoteDbUri) {
      console.log('\n----------------------------------------------');
      console.log('Updating MongoDB Atlas');
      console.log('----------------------------------------------');
      await updateHash(remoteDbUri, sha256, sizeBytes);
    }

    console.log('\n==============================================');
    console.log(' UPDATE COMPLETE');
    console.log('==============================================');
  } catch (error) {
    console.error('\n==============================================');
    console.error(' UPDATE FAILED');
    console.error('==============================================');
    console.error(error);
    process.exit(1);
  }
}

main();
