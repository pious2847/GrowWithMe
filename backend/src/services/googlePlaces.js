const axios = require('axios');
const env = require('../config/env');
const logger = require('../utils/logger');

const configured = () => Boolean(process.env.GOOGLE_MAPS_API_KEY);

/**
 * Real-world emergency fallback: when no registered facility is in range,
 * ask Google Places for the closest hospital/health facility and its phone
 * number so the alert flow can still notify someone. Best-effort — returns
 * null on any failure.
 */
async function findNearestHospital(lng, lat) {
  if (!configured()) return null;
  const key = process.env.GOOGLE_MAPS_API_KEY;
  try {
    const nearby = await axios.get(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
      {
        params: {
          location: `${lat},${lng}`,
          rankby: 'distance',
          type: 'hospital',
          keyword: 'hospital clinic health',
          key,
        },
        timeout: 10000,
      }
    );
    const place = (nearby.data.results || [])[0];
    if (!place) return null;

    const details = await axios.get(
      'https://maps.googleapis.com/maps/api/place/details/json',
      {
        params: {
          place_id: place.place_id,
          fields: 'name,formatted_phone_number,international_phone_number,vicinity,geometry',
          key,
        },
        timeout: 10000,
      }
    );
    const d = details.data.result || {};
    const phone = d.international_phone_number || d.formatted_phone_number || null;
    logger.info(`[places] nearest hospital: ${d.name || place.name} phone=${phone || 'none'}`);
    return {
      name: d.name || place.name,
      phone,
      address: d.vicinity || place.vicinity || '',
    };
  } catch (err) {
    logger.error('[places] lookup failed:', err.message);
    return null;
  }
}

module.exports = { findNearestHospital, configured };
