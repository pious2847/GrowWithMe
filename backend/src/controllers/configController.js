const {
  listCountries,
  getCountry,
  getCountryOrDefault,
} = require('../config/regions');

const APP_CONFIG = {
  appId: 'growwithme',
  latestVersion: '1.0.0',
  minSupportedVersion: '1.0.0',
  features: {
    nanaCompanion: true,
    offlineTriage: true,
    offlineVitalsModel: true,
    offlineNlu: true,
    offlineSlm: false,
    careCircle: true,
    dietPlanner: true,
    growthCharts: true,
    actionDatasetLogging: true,
  },
  supportedLanguages: ['en', 'tw', 'dag', 'ha', 'sw', 'lg', 'fr'],
  actionSchemaVersion: 3,
  dataset: {
    purpose: 'On-device navigation/action model training',
    consentRequired: true,
    allowListOnly: true,
  },
};

/** GET /api/v1/config/app — public bootstrap config. */
function app(req, res) {
  res.json({ ...APP_CONFIG, updatedAt: new Date().toISOString() });
}

/** GET /api/v1/config/regions — public list of care packs. */
function regions(req, res) {
  res.json({ countries: listCountries() });
}

/**
 * GET /api/v1/config/regions/:code — one care pack.
 *
 * Unknown ISO codes deliberately fall back to the international pack instead
 * of 404ing: a caregiver anywhere in the world must still get safe guidance.
 */
function region(req, res, next) {
  try {
    const country = getCountry(req.params.code);
    res.json({
      ...getCountryOrDefault(req.params.code),
      fallback: !country,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { app, regions, region };
