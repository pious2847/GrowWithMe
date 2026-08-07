/**
 * Registers/updates an on-device model manifest in the MlModel registry.
 * Usage: node scripts/register_model.js [--env atlas-credentials.env]
 * Edit MANIFEST below when publishing a new version (bump `version`!).
 */
const path = require('path');
const envFile = process.argv.includes('--env')
  ? process.argv[process.argv.indexOf('--env') + 1]
  : '.env';
require('dotenv').config({ path: path.join(__dirname, '..', envFile) });

// Some ISP resolvers refuse the SRV lookups mongodb+srv:// needs — use
// public DNS so the script works everywhere.
require('dns').setServers(['8.8.8.8', '1.1.1.1']);

const mongoose = require('mongoose');
const MlModel = require('../src/models/MlModel');

const MANIFEST = {
  name: 'maternal-risk',
  version: 1,
  kind: 'tflite',
  url: 'https://res.cloudinary.com/dj3qeohxn/raw/upload/v1786127015/growwithme/models/maternal_risk_v1.tflite',
  sha256: '1bbc1b6009e11055cd48a491900bc1fe2fe2ff2f7519b9c00f6a69cdb1695545',
  sizeBytes: 6116,
  active: true,
  meta: {
    classes: ['low risk', 'mid risk', 'high risk'],
    features: ['age', 'systolic_bp', 'diastolic_bp', 'blood_sugar', 'body_temp', 'heart_rate'],
    featureLabels: [
      'Age (years)',
      'Systolic BP (mmHg)',
      'Diastolic BP (mmHg)',
      'Blood sugar (mmol/L)',
      'Body temperature (°F)',
      'Heart rate (bpm)',
    ],
    validRanges: {
      age: [10, 70],
      systolic_bp: [60, 220],
      diastolic_bp: [40, 140],
      blood_sugar: [3, 25],
      body_temp: [95, 106],
      heart_rate: [40, 200],
    },
    mean: [29.32, 111.04, 75.62, 8.39, 98.66, 74.42],
    std: [13.93, 17.86, 13.93, 2.92, 1.38, 7.54],
    inputLayout: 'six normalized values (0 where missing) followed by six presence flags',
    // Evaluation showed age+BP alone collapses (high-risk recall 0.61) while
    // age+BP+temp holds up (0.87) — so a prediction requires BP + age and at
    // least 4 of 6 inputs. The apps MUST enforce this.
    minInputs: 4,
    requiredFeatures: ['age', 'systolic_bp', 'diastolic_bp'],
    eval: {
      testRows: 91,
      highRiskRecall: { allSix: 0.913, caregiverPattern: 0.87, ageBpOnly: 0.609 },
      accuracy: { allSix: 0.714, caregiverPattern: 0.637 },
    },
    trainedOn: 'UCI Maternal Health Risk (Bangladesh, deduplicated to 452 rows), local rows: 0',
    disclaimer:
      'Decision support only — the AI can be wrong. It never downgrades the danger-sign rules.',
  },
};

async function main() {
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;
  if (!uri) throw new Error(`No MONGO_URI/MONGODB_URI in ${envFile}`);
  await mongoose.connect(uri);
  console.log(`[register_model] connected to ${mongoose.connection.name}`);
  const { name, version, url, sha256, sizeBytes, kind, active, meta } = MANIFEST;
  const doc = await MlModel.findOneAndUpdate(
    { name },
    { name, version, url, sha256, sizeBytes, kind, active, meta },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );
  console.log(`[register_model] ${doc.name} v${doc.version} registered (${doc.sizeBytes} bytes)`);
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
