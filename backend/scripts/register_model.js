/**
 * Registers/updates an on-device model manifest in the MlModel registry.
 * Usage: node scripts/register_model.js [--env atlas-credentials.env] [--name maternal-risk|nana-nlu]
 * Default registers ALL manifests below. Bump `version` when publishing a new file!
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

const NANA_NLU_MANIFEST = {
  name: 'nana-nlu',
  version: 2,
  kind: 'tflite',
  url: 'https://res.cloudinary.com/dj3qeohxn/raw/upload/v1786133632/growwithme/models/nana_nlu_v2.tflite',
  sha256: '8187f9d7b5601bdb89f6003c34e9d37a8451abdc2da787a6c84628bf976693ff',
  sizeBytes: 1057136,
  active: true,
  meta: {
    intents: [
      'start_health_check', 'open_add_child', 'open_add_pregnancy', 'plan_diet',
      'read_today', 'get_tip', 'log_weight', 'set_reminder', 'greeting', 'help_other',
      'ask_danger_signs', 'ask_feeding_question', 'ask_vaccine', 'find_clinic',
      'open_calendar', 'open_tips', 'start_checkin',
    ],
    subjects: ['child', 'pregnancy', 'unknown'],
    buckets: 8192,
    featurizer:
      "lowercase; [^a-z0-9' ]->space; unigrams u:, bigrams b:_, char trigrams c: of ^tok$; fnv1a32 % buckets; L2 norm",
    outputLayout: 'concat: intents then subjects',
    minConfidence: 0.5,
    eval: {
      hardTestIntent: '23/23',
      hardTestSubject: '22/23',
      heldOutIntentAccuracy: 1.0,
      heldOutSubjectAccuracy: 0.997,
    },
    trainedOn: '5201 examples (Ghana-grounded generator: Pidgin, SMS noise, local foods, hard negatives), v2',
    disclaimer:
      'Understanding only — replies are curated in-app; the model never generates text.',
  },
};

const MATERNAL_RISK_MANIFEST = {
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

const MANIFESTS = [MATERNAL_RISK_MANIFEST, NANA_NLU_MANIFEST];

async function main() {
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;
  if (!uri) throw new Error(`No MONGO_URI/MONGODB_URI in ${envFile}`);
  const only = process.argv.includes('--name')
    ? process.argv[process.argv.indexOf('--name') + 1]
    : null;
  await mongoose.connect(uri);
  console.log(`[register_model] connected to ${mongoose.connection.name}`);
  for (const manifest of MANIFESTS) {
    if (only && manifest.name !== only) continue;
    const { name, version, url, sha256, sizeBytes, kind, active, meta } = manifest;
    const doc = await MlModel.findOneAndUpdate(
      { name },
      { name, version, url, sha256, sizeBytes, kind, active, meta },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );
    console.log(`[register_model] ${doc.name} v${doc.version} registered (${doc.sizeBytes} bytes)`);
  }
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
