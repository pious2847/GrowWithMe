// Seeds demo data for the hackathon: facilities around Tamale (Northern
// Region), one community health volunteer, and one facility staff account.
// Run: npm run seed
const mongoose = require('mongoose');
const env = require('../config/env');
const { connectDB } = require('../config/db');
const Facility = require('../models/Facility');
const User = require('../models/User');

const FACILITIES = [
  {
    name: 'Tamale Teaching Hospital',
    type: 'hospital',
    phone: '0372022454',
    region: 'Northern',
    district: 'Tamale Metropolitan',
    location: { type: 'Point', coordinates: [-0.8393, 9.4008] },
  },
  {
    name: 'Tamale Central Hospital',
    type: 'hospital',
    phone: '0372022200',
    region: 'Northern',
    district: 'Tamale Metropolitan',
    location: { type: 'Point', coordinates: [-0.8534, 9.4126] },
  },
  {
    name: 'Kalpohin Health Centre',
    type: 'health_centre',
    phone: '0240000001',
    region: 'Northern',
    district: 'Tamale Metropolitan',
    location: { type: 'Point', coordinates: [-0.8724, 9.4247] },
  },
  {
    name: 'Vittin CHPS Compound',
    type: 'chps',
    phone: '0240000002',
    region: 'Northern',
    district: 'Tamale Metropolitan',
    location: { type: 'Point', coordinates: [-0.8055, 9.3931] },
  },
  {
    name: 'Savelugu Municipal Hospital',
    type: 'hospital',
    phone: '0240000003',
    region: 'Northern',
    district: 'Savelugu Municipal',
    location: { type: 'Point', coordinates: [-0.8261, 9.6244] },
  },
];

async function seed() {
  await connectDB();

  await Facility.deleteMany({});
  const facilities = await Facility.insertMany(FACILITIES);
  console.log(`[seed] inserted ${facilities.length} facilities`);

  const chps = facilities.find((f) => f.type === 'chps');

  await User.findOneAndUpdate(
    { phone: '233240000010' },
    {
      phone: '233240000010',
      name: 'Abdul Volunteer',
      role: 'volunteer',
      language: 'dagbani',
      region: 'Northern',
      district: 'Tamale Metropolitan',
      community: 'Vittin',
      available: true,
      facility: chps._id,
      location: { type: 'Point', coordinates: [-0.81, 9.395] },
      consent: { dataProcessing: true, locationOnUrgent: true, smsReminders: true, consentedAt: new Date() },
    },
    { upsert: true, new: true }
  );
  console.log('[seed] upserted demo volunteer (233240000010)');

  const hospital = facilities.find((f) => f.name === 'Tamale Teaching Hospital');
  await User.findOneAndUpdate(
    { phone: '233240000011' },
    {
      phone: '233240000011',
      name: 'Nurse Fatima',
      role: 'facility',
      region: 'Northern',
      district: 'Tamale Metropolitan',
      facility: hospital._id,
      consent: { dataProcessing: true, locationOnUrgent: false, smsReminders: true, consentedAt: new Date() },
    },
    { upsert: true, new: true }
  );
  console.log('[seed] upserted demo facility staff (233240000011)');

  await mongoose.disconnect();
  console.log('[seed] done');
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
