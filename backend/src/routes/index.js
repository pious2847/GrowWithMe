const { Router } = require('express');
const multer = require('multer');

const { requireAuth, requireRole } = require('../middleware/auth');
const { rateLimit, phoneKey, userKey } = require('../middleware/rateLimit');
const authController = require('../controllers/authController');
const userController = require('../controllers/userController');
const syncController = require('../controllers/syncController');
const alertController = require('../controllers/alertController');
const facilityController = require('../controllers/facilityController');
const uploadController = require('../controllers/uploadController');
const dashboardController = require('../controllers/dashboardController');
const assistantController = require('../controllers/assistantController');
const responderController = require('../controllers/responderController');
const modelController = require('../controllers/modelController');
const actionController = require('../controllers/actionController');
const configController = require('../controllers/configController');

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB — voice notes and photos
});

// Abuse limits. OTP sends cost real SMS money and AI calls cost tokens, so
// those are the tightest; everything else gets a generous per-caller ceiling.
const otpByPhone = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  key: (req) => `phone:${phoneKey(req)}`,
  message: 'Too many codes requested for this number. Please wait 15 minutes.',
});
const otpByIp = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 25,
  key: (req) => `ip:${req.ip}`,
  message: 'Too many codes requested from this connection. Please wait 15 minutes.',
});
const verifyByCaller = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  key: (req) => `phone:${phoneKey(req)}|ip:${req.ip}`,
});
const aiLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 40,
  key: (req) => `user:${userKey(req)}`,
  message: 'Nana needs a short rest. Please try again later.',
});
const syncLimit = rateLimit({
  windowMs: 60 * 1000,
  max: 120,
  key: (req) => `user:${userKey(req)}`,
});
const eventLimit = rateLimit({
  windowMs: 60 * 1000,
  max: 240,
  key: (req) => `user:${userKey(req)}`,
});
const uploadLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 30,
  key: (req) => `user:${userKey(req)}`,
  message: 'Too many uploads. Please try again later.',
});

// Public configuration: country care packs, feature flags, minimum version.
// Needed before login so onboarding can choose the right care pack.
router.get('/config/app', configController.app);
router.get('/config/regions', configController.regions);
router.get('/config/regions/:code', configController.region);

// Auth
router.post('/auth/request-otp', otpByIp, otpByPhone, authController.requestOtp);
router.post('/auth/verify-otp', verifyByCaller, authController.verifyOtp);
router.post('/auth/refresh', authController.refresh);

// Profile
router.get('/users/me', requireAuth, userController.getMe);
router.patch('/users/me', requireAuth, userController.updateMe);
router.delete('/users/me', requireAuth, userController.deleteMe);

// Local-first sync
router.post('/sync', requireAuth, syncLimit, syncController.sync);

// Consented interaction events for the on-device action model dataset.
// Allow-listed metadata only; no free text and no health values.
router.post('/actions/events', requireAuth, eventLimit, actionController.ingest);
router.get(
  '/actions/summary',
  requireAuth,
  requireRole('admin'),
  actionController.summary
);
router.get(
  '/actions/export',
  requireAuth,
  requireRole('admin'),
  actionController.exportDataset
);

// Alerts / referral loop
router.get('/alerts', requireAuth, alertController.listAlerts);
router.get('/alerts/:id', requireAuth, alertController.getAlert);
router.patch('/alerts/:id/status', requireAuth, alertController.updateStatus);

// Facilities
router.get('/facilities', requireAuth, facilityController.list);
router.get('/facilities/nearby', requireAuth, facilityController.nearby);
router.post('/facilities', requireAuth, requireRole('admin'), facilityController.create);
router.post(
  '/facilities/bulk',
  requireAuth,
  requireRole('admin'),
  facilityController.bulkImport
);
router.patch('/facilities/:id', requireAuth, requireRole('admin'), facilityController.update);

// Uploads (Cloudinary)
router.post('/uploads', requireAuth, uploadLimit, upload.single('file'), uploadController.upload);

// Responder app (volunteers, CHWs, nurses, midwives, doctors)
router.post('/responder/profile', requireAuth, responderController.saveProfile);
router.post(
  '/responder/documents',
  requireAuth,
  upload.single('file'),
  responderController.uploadDocument
);
router.post('/responder/location', requireAuth, responderController.updateLocation);
router.post('/responder/availability', requireAuth, responderController.setAvailability);
router.get('/responder/alerts', requireAuth, responderController.nearbyAlerts);

// Admin: responder verification queue
router.get(
  '/admin/responders/pending',
  requireAuth,
  requireRole('admin'),
  responderController.pendingResponders
);
router.post(
  '/admin/responders/:id/verify',
  requireAuth,
  requireRole('admin'),
  responderController.verifyResponder
);

// On-device model registry: apps poll the manifest, then background-download
// the model file from its URL (see OFFLINE_MODEL_PLAN.md)
router.get('/models/:name', requireAuth, modelController.getModel);
router.post('/models/:name/log', requireAuth, modelController.logAssessment);
router.post('/admin/models', requireAuth, requireRole('admin'), modelController.upsertModel);

// Nana — AI care educator (LLM proxy + natural voice)
router.post('/assistant/chat', requireAuth, aiLimit, assistantController.chat);
router.post('/assistant/speak', requireAuth, aiLimit, assistantController.speak);
router.post('/assistant/checkin-questions', requireAuth, aiLimit, assistantController.checkinQuestions);
router.post('/assistant/diet-plan', requireAuth, aiLimit, assistantController.dietPlan);
router.post('/assistant/daily-tips', requireAuth, aiLimit, assistantController.dailyTips);

// Facility dashboard + monitoring queue
router.get(
  '/dashboard/catchment',
  requireAuth,
  requireRole('facility', 'admin'),
  dashboardController.catchment
);
router.get(
  '/dashboard/signals',
  requireAuth,
  requireRole('facility', 'admin'),
  dashboardController.signals
);
router.post(
  '/dashboard/scan',
  requireAuth,
  requireRole('facility', 'admin'),
  dashboardController.triggerScan
);
router.patch(
  '/dashboard/signals/:id',
  requireAuth,
  requireRole('facility', 'admin'),
  dashboardController.updateSignal
);

module.exports = router;
