/**
 * Country care packs. Each pack carries what makes guidance locally correct:
 * administrative regions, emergency numbers, languages, the national
 * immunization schedule, and locally familiar foods. Adding a country is a
 * data change, not a code change.
 */

const GHANA_REGIONS = [
  'Northern', 'Savannah', 'North East', 'Upper East', 'Upper West',
  'Ashanti', 'Bono', 'Bono East', 'Ahafo', 'Central', 'Eastern',
  'Greater Accra', 'Oti', 'Volta', 'Western', 'Western North',
];

const GHANA = {
  code: 'GH',
  name: 'Ghana',
  flag: '🇬🇭',
  dialCode: '+233',
  homeMarket: true,
  emergency: { general: '112', ambulance: '193', police: '191' },
  languages: [
    { code: 'en', label: 'English', status: 'stable' },
    { code: 'tw', label: 'Twi', status: 'beta' },
    { code: 'dag', label: 'Dagbani', status: 'beta' },
  ],
  regions: GHANA_REGIONS,
  immunizationSchedule: 'ghana-epi-2024',
  growthStandard: 'WHO-2006',
  localFoods: [
    'TZ (tuo zaafi)', 'koko', 'moringa', 'dawadawa', 'ayoyo', 'bean stew',
    'groundnut soup', 'kenkey', 'kontomire', 'smoked fish', 'soya beans',
  ],
  policies: {
    dataProtection: 'Ghana Data Protection Act, 2012 (Act 843)',
    privacyContact: 'privacy@tovolabs.com',
  },
};

const NIGERIA = {
  code: 'NG',
  name: 'Nigeria',
  flag: '🇳🇬',
  dialCode: '+234',
  emergency: { general: '112', ambulance: '112', police: '112' },
  languages: [
    { code: 'en', label: 'English', status: 'stable' },
    { code: 'ha', label: 'Hausa', status: 'beta' },
  ],
  regions: ['Lagos', 'Kano', 'Kaduna', 'Oyo', 'Abuja FCT', 'Enugu'],
  immunizationSchedule: 'nigeria-npi-2024',
  growthStandard: 'WHO-2006',
  localFoods: ['millet pap', 'moi moi', 'egusi', 'okra soup', 'groundnut'],
  policies: { dataProtection: 'Nigeria Data Protection Act, 2023' },
};

const KENYA = {
  code: 'KE',
  name: 'Kenya',
  flag: '🇰🇪',
  dialCode: '+254',
  emergency: { general: '999', ambulance: '999', police: '999' },
  languages: [
    { code: 'en', label: 'English', status: 'stable' },
    { code: 'sw', label: 'Kiswahili', status: 'beta' },
  ],
  regions: ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret'],
  immunizationSchedule: 'kenya-epi-2024',
  growthStandard: 'WHO-2006',
  localFoods: ['ugali', 'sukuma wiki', 'githeri', 'uji', 'beans'],
  policies: { dataProtection: 'Kenya Data Protection Act, 2019' },
};

const UGANDA = {
  code: 'UG',
  name: 'Uganda',
  flag: '🇺🇬',
  dialCode: '+256',
  emergency: { general: '112', ambulance: '112', police: '999' },
  languages: [
    { code: 'en', label: 'English', status: 'stable' },
    { code: 'lg', label: 'Luganda', status: 'beta' },
  ],
  regions: ['Kampala', 'Gulu', 'Mbarara', 'Mbale'],
  immunizationSchedule: 'uganda-unepi-2024',
  growthStandard: 'WHO-2006',
  localFoods: ['matoke', 'posho', 'beans', 'groundnut sauce', 'silver fish'],
  policies: { dataProtection: 'Uganda Data Protection and Privacy Act, 2019' },
};

const TANZANIA = {
  code: 'TZ',
  name: 'Tanzania',
  flag: '🇹🇿',
  dialCode: '+255',
  emergency: { general: '112', ambulance: '114', police: '110' },
  languages: [
    { code: 'en', label: 'English', status: 'stable' },
    { code: 'sw', label: 'Kiswahili', status: 'beta' },
  ],
  regions: ['Dar es Salaam', 'Mwanza', 'Arusha', 'Dodoma'],
  immunizationSchedule: 'tanzania-epi-2024',
  growthStandard: 'WHO-2006',
  localFoods: ['ugali', 'mchicha', 'dagaa', 'beans', 'banana'],
  policies: { dataProtection: 'Tanzania Personal Data Protection Act, 2022' },
};

/**
 * Fallback pack for every other country. English/French guidance, the WHO
 * growth standard and 112 are safe defaults; specific packs override them.
 */
const INTERNATIONAL = {
  code: 'XX',
  name: 'Another country',
  flag: '🌍',
  dialCode: '+',
  international: true,
  emergency: { general: '112', ambulance: '112', police: '112' },
  languages: [
    { code: 'en', label: 'English', status: 'stable' },
    { code: 'fr', label: 'Français', status: 'beta' },
  ],
  regions: [],
  immunizationSchedule: 'who-epi',
  growthStandard: 'WHO-2006',
  localFoods: [
    'rice', 'maize', 'millet', 'sorghum', 'potatoes', 'cassava', 'beans',
    'lentils', 'eggs', 'dark green leaves', 'small dried fish', 'yoghurt',
  ],
  policies: {
    dataProtection: 'GDPR and applicable local law',
    privacyContact: 'privacy@tovolabs.com',
  },
};

const COUNTRIES = [GHANA, NIGERIA, KENYA, UGANDA, TANZANIA, INTERNATIONAL];

function listCountries() {
  return COUNTRIES;
}

function getCountry(code) {
  if (!code) return null;
  return COUNTRIES.find((c) => c.code === String(code).toUpperCase()) || null;
}

function getCountryOrDefault(code) {
  return getCountry(code) || INTERNATIONAL;
}

module.exports = { listCountries, getCountry, getCountryOrDefault, INTERNATIONAL };
