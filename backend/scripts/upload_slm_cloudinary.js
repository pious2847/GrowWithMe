/**
 * Uploads the nana_slm_v1.zip to Cloudinary and registers it in the database
 * Usage: node scripts/upload_slm_cloudinary.js [--env atlas-credentials.env]
 */
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const cloudinary = require('cloudinary').v2;

const envFile = process.argv.includes('--env')
  ? process.argv[process.argv.indexOf('--env') + 1]
  : '.env';
require('dotenv').config({ path: path.join(__dirname, '..', envFile) });

// Use public DNS for MongoDB
require('dns').setServers(['8.8.8.8', '1.1.1.1']);

const mongoose = require('mongoose');
const MlModel = require('../src/models/MlModel');

const MODEL_NAME = 'nana-slm';
const ZIP_PATH = path.join(__dirname, 'nana_slm_v1.zip');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

function calculateFileInfo(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`ZIP file not found: ${filePath}`);
  }

  const buffer = fs.readFileSync(filePath);
  const sha256 = crypto.createHash('sha256').update(buffer).digest('hex');

  return {
    buffer,
    sizeBytes: buffer.length,
    sha256,
  };
}

async function uploadToCloudinary(buffer) {
  console.log('Uploading to Cloudinary...');
  
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: 'growwithme/models',
        resource_type: 'raw',
        public_id: 'nana_slm_v1',
      },
      (error, result) => {
        if (error) {
          reject(error);
        } else {
          resolve(result);
        }
      }
    );
    stream.end(buffer);
  });
}

async function publishToDatabase(dbUri, manifest) {
  const isAtlas = dbUri.includes('mongodb+srv');
  console.log(`\nConnecting to ${isAtlas ? 'MongoDB Atlas' : 'Local MongoDB'}...`);

  const conn = await mongoose.createConnection(dbUri).asPromise();

  try {
    const Model = conn.model('MlModel', MlModel.schema);

    const existing = await Model.findOne({ name: MODEL_NAME });
    const nextVersion = existing ? Number(existing.version || 0) + 1 : 1;

    const finalManifest = {
      ...manifest,
      version: nextVersion,
      active: true,
    };

    const doc = await Model.findOneAndUpdate(
      { name: MODEL_NAME },
      { $set: finalManifest },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    console.log(
      `Published ${MODEL_NAME} v${doc.version} to ${isAtlas ? 'MongoDB Atlas' : 'Local MongoDB'}`
    );
    console.log(`Active: ${doc.active}`);
    console.log(`URL: ${doc.url}`);
    console.log(`SHA256: ${doc.sha256}`);

    return doc;
  } finally {
    await conn.close();
  }
}

async function main() {
  console.log('==============================================');
  console.log(' GrowWithMe Nana SLM Cloudinary Upload');
  console.log('==============================================');

  try {
    // 1. Check ZIP and calculate hash
    console.log('\nChecking model package...');
    const info = calculateFileInfo(ZIP_PATH);
    console.log(`ZIP: ${ZIP_PATH}`);
    console.log(`Size: ${(info.sizeBytes / 1024 / 1024).toFixed(2)} MB`);
    console.log(`SHA256: ${info.sha256}`);

    // 2. Upload to Cloudinary
    const uploadResult = await uploadToCloudinary(info.buffer);
    console.log('\nCloudinary upload successful!');
    console.log(`Secure URL: ${uploadResult.secure_url}`);
    console.log(`Public ID: ${uploadResult.public_id}`);

    // 3. Build manifest with Cloudinary URL
    const manifest = {
      name: MODEL_NAME,
      kind: 'llm',
      url: uploadResult.secure_url,
      sha256: info.sha256,
      sizeBytes: info.sizeBytes,
      active: true,
      meta: {
        trainedOn: 'Llama 3.2 on 55k synthetic maternal health conversations',
        disclaimer: 'Fine-tuned SLM on-device adapter.',
        source: 'Cloudinary - growwithme/models/nana_slm_v1',
        file: 'nana_slm_v1.zip',
      },
    };

    // 4. Publish to Local MongoDB
    const localDbUri = process.env.MONGO_URI || process.env.MONGODB_URI;
    if (localDbUri) {
      console.log('\n----------------------------------------------');
      console.log('Publishing to local MongoDB');
      console.log('----------------------------------------------');
      await publishToDatabase(localDbUri, manifest);
    }

    // 5. Publish to MongoDB Atlas
    const remoteDbUri = process.env.MONGODB_ATLAS_URI;
    if (remoteDbUri) {
      console.log('\n----------------------------------------------');
      console.log('Publishing to MongoDB Atlas');
      console.log('----------------------------------------------');
      await publishToDatabase(remoteDbUri, manifest);
    }

    console.log('\n==============================================');
    console.log(' UPLOAD COMPLETE');
    console.log('==============================================');
    console.log(`\nModel URL: ${uploadResult.secure_url}`);
    console.log(`SHA256: ${info.sha256}`);
    console.log(`Size: ${(info.sizeBytes / 1024 / 1024).toFixed(2)} MB`);
  } catch (error) {
    console.error('\n==============================================');
    console.error(' UPLOAD FAILED');
    console.error('==============================================');
    console.error(error);
    process.exit(1);
  }
}

main();
