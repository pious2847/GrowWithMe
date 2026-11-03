const logger = require('../utils/logger');
const { userRef } = require('../utils/privacy');

/**
 * Logs every request with method, path, status, duration, response size and a
 * pseudonymous user reference (when authenticated). Runs in all environments —
 * this is the "did the app's request actually reach me?" trail. Phone numbers
 * and health context never enter the log line.
 */
module.exports = function requestLogger(req, res, next) {
  const start = process.hrtime.bigint();
  res.on('finish', () => {
    const ms = Number(process.hrtime.bigint() - start) / 1e6;
    const size = res.getHeader('content-length');
    const user = req.user ? ` user=${userRef(req.user)}` : '';
    const line =
      `${req.method} ${req.originalUrl} -> ${res.statusCode} ` +
      `${ms.toFixed(1)}ms${size ? ` ${size}b` : ''}${user}`;
    if (res.statusCode >= 500) logger.error(line);
    else if (res.statusCode >= 400) logger.warn(line);
    else logger.info(line);
  });
  next();
};
