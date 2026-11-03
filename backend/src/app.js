const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');

const env = require('./config/env');
const routes = require('./routes');
const requestLogger = require('./middleware/requestLogger');
const { rateLimit } = require('./middleware/rateLimit');
const { notFound, errorHandler } = require('./middleware/error');
const pkg = require('../package.json');

const app = express();

// Render/most PaaS terminate TLS ahead of us; trust one proxy hop so req.ip
// and the rate limiter see the real caller instead of the load balancer.
if (env.isProd) app.set('trust proxy', 1);

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(requestLogger);

const DB_STATES = ['disconnected', 'connected', 'connecting', 'disconnecting'];

// Liveness: must stay cheap and successful even while Mongo reconnects.
app.get('/health', (req, res) =>
  res.json({
    ok: true,
    service: 'growwithme-backend',
    version: pkg.version,
    uptimeSeconds: Math.round(process.uptime()),
  })
);

// Readiness: used by deploys and uptime monitors that should wait for Mongo.
app.get('/health/ready', (req, res) => {
  const dbState = DB_STATES[mongoose.connection.readyState] || 'unknown';
  const ready = mongoose.connection.readyState === 1;
  res.status(ready ? 200 : 503).json({
    ok: ready,
    service: 'growwithme-backend',
    version: pkg.version,
    db: dbState,
    uptimeSeconds: Math.round(process.uptime()),
  });
});

// Broad safety net per caller. Auth, AI and uploads add tighter limits on
// their own routes.
app.use(
  '/api/v1',
  rateLimit({
    windowMs: 60 * 1000,
    max: Math.max(60, parseInt(process.env.API_RATE_LIMIT_PER_MIN || '600', 10)),
    key: (req) => req.ip,
  })
);

// Alert deep link — the URL that travels by SMS to responders. Public page
// with NO patient details (those need the authenticated app): it shows the
// live status and hands off to the responder app via the custom scheme.
app.get('/a/:id', async (req, res) => {
  const Alert = require('./models/Alert');
  let alert = null;
  try {
    alert = await Alert.findById(req.params.id).select('status createdAt').lean();
  } catch (_) {}
  if (!alert) return res.status(404).send('Alert not found');
  const appLink = `growwithme://alert/${req.params.id}`;
  res.send(`<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>GrowWithMe — Urgent case</title>
<style>
body{font-family:system-ui,sans-serif;margin:0;background:#F1F8E9;color:#1B5E20;display:flex;min-height:100vh;align-items:center;justify-content:center}
.card{background:#fff;border-radius:16px;padding:28px;margin:16px;max-width:420px;box-shadow:0 4px 16px rgba(0,0,0,.08);text-align:center}
.badge{display:inline-block;background:#B71C1C;color:#fff;font-weight:700;border-radius:99px;padding:6px 16px;margin-bottom:12px}
a.btn{display:block;background:#1B5E20;color:#fff;text-decoration:none;font-weight:700;border-radius:12px;padding:14px;margin-top:18px}
p{color:#444;line-height:1.5}</style></head>
<body><div class="card">
<div class="badge">URGENT CASE</div>
<h2>GrowWithMe referral</h2>
<p>Status: <b>${alert.status.replace('_', ' ')}</b><br>
Raised: ${new Date(alert.createdAt).toUTCString()}</p>
<p>Open this case in the GrowWithMe Responder app to see the patient report, location and actions.</p>
<a class="btn" href="${appLink}">Open in Responder app</a>
</div></body></html>`);
});

app.use('/api/v1', routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
