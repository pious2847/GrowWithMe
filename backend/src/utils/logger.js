const fs = require('fs');
const path = require('path');

const LOG_DIR = path.join(__dirname, '..', '..', 'logs');
const LOG_FILE = path.join(LOG_DIR, 'app.log');
fs.mkdirSync(LOG_DIR, { recursive: true });

const COLORS = {
  INFO: '\x1b[36m',
  WARN: '\x1b[33m',
  ERROR: '\x1b[31m',
  DEBUG: '\x1b[90m',
  DIM: '\x1b[90m',
  RESET: '\x1b[0m',
};

function timestamp() {
  const d = new Date();
  const pad = (n, w = 2) => String(n).padStart(w, '0');
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}.${pad(d.getMilliseconds(), 3)}`
  );
}

function serialize(arg) {
  if (arg instanceof Error) return arg.stack || arg.message;
  if (typeof arg === 'object' && arg !== null) {
    try {
      return JSON.stringify(arg);
    } catch {
      return String(arg);
    }
  }
  return String(arg);
}

function write(level, args) {
  const msg = args.map(serialize).join(' ');
  const ts = timestamp();
  const color = COLORS[level] || '';
  // Console: colored and readable
  console.log(`${COLORS.DIM}${ts}${COLORS.RESET} ${color}${level.padEnd(5)}${COLORS.RESET} ${msg}`);
  // File: plain text, survives restarts and closed terminals
  fs.appendFile(LOG_FILE, `${ts} ${level.padEnd(5)} ${msg}\n`, () => {});
}

module.exports = {
  info: (...args) => write('INFO', args),
  warn: (...args) => write('WARN', args),
  error: (...args) => write('ERROR', args),
  debug: (...args) => write('DEBUG', args),
  LOG_FILE,
};
