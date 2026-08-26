const path = require('path');
const { exec } = require('child_process');
const mongoose = require('mongoose');
const MlModel = require('../src/models/MlModel');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
require('dns').setServers(['8.8.8.8', '1.1.1.1']);

// Database URL from arguments or env or default to Atlas
const dbUri = process.argv[2] || process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb+srv://abdulhafis2847_db_user:DQA1Nhiiglqtl47G@growwithme.ol0wykb.mongodb.net/growwithme';

const pythonScript = path.join(__dirname, 'package_slm.py');

console.log('Running python packaging and Hugging Face uploading script...');
exec(`python "${pythonScript}"`, async (error, stdout, stderr) => {
  if (error) {
    console.error(`Python script error: ${error.message}`);
    console.error(stderr);
    process.exit(1);
  }
  
  console.log(stdout);
  
  if (!stdout.includes('PACK_SUCCESS')) {
    console.error('Packaging failed!');
    process.exit(1);
  }
  
  const lines = stdout.split('\n');
  const jsonLine = lines.find(l => l.trim().startsWith('{'));
  if (!jsonLine) {
    console.error('Could not find JSON output from python script.');
    process.exit(1);
  }
  
  const info = JSON.parse(jsonLine);
  
  try {
    console.log(`Connecting to database at ${dbUri}...`);
    await mongoose.connect(dbUri);
    console.log(`Connected to database ${mongoose.connection.name}`);
    
    const manifest = {
      name: 'nana-slm',
      version: 1,
      kind: 'llm',
      url: info.zipUrl,
      sha256: info.sha256,
      sizeBytes: info.sizeBytes,
      active: true,
      meta: {
        trainedOn: 'Llama 3.2 on 55k synthetic maternal health conversations',
        disclaimer: 'Fine-tuned SLM on-device adapter.',
      }
    };
    
    const doc = await MlModel.findOneAndUpdate(
      { name: manifest.name },
      manifest,
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );
    
    console.log(`Successfully registered model: ${doc.name} v${doc.version} (${doc.sizeBytes} bytes)`);
    console.log(`Model URL: ${doc.url}`);
    
    await mongoose.disconnect();
    console.log('Database disconnected. Done!');
  } catch (err) {
    console.error('Error during deployment:', err);
    process.exit(1);
  }
});
