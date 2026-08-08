const env = require('../config/env');
const ApiError = require('../utils/apiError');
const logger = require('../utils/logger');

function notFound(req, res, next) {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  let status = err.statusCode || 500;
  let message = err.message || 'Internal server error';

  if (err.name === 'ValidationError') {
    status = 400;
    message = Object.values(err.errors)
      .map((e) => e.message)
      .join('; ');
  } else if (err.code === 11000) {
    status = 409;
    message = 'Duplicate value for a unique field';
  }

  // Expected unavailability (e.g. voice provider quota cooldown) is a fact,
  // not a fault — one WARN line, no stack trace. Real 5xx keep the full dump.
  if (err instanceof ApiError && status === 503) {
    logger.warn(`${req.method} ${req.originalUrl} -> 503: ${message}`);
  } else if (status >= 500) {
    logger.error(`${req.method} ${req.originalUrl} failed:`, err);
  }

  res.status(status).json({
    success: false,
    message,
    ...(err.details ? { details: err.details } : {}),
    ...(env.isProd ? {} : { stack: err.stack }),
  });
}

module.exports = { notFound, errorHandler };
