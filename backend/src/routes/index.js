const { Router } = require('express');
const multer = require('multer');

const { requireAuth, requireRole } = require('../middleware/auth');
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

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB — voice notes and photos
});

// Auth
router.post('/auth/request-otp', authController.requestOtp);
router.post('/auth/verify-otp', authController.verifyOtp);
router.post('/auth/refresh', authController.refresh);

// Profile
router.get('/users/me', requireAuth, userController.getMe);
router.patch('/users/me', requireAuth, userController.updateMe);
router.delete('/users/me', requireAuth, userController.deleteMe);

// Local-first sync
router.post('/sync', requireAuth, syncController.sync);

// Alerts / referral loop
router.get('/alerts', requireAuth, alertController.listAlerts);
router.get('/alerts/:id', requireAuth, alertController.getAlert);
router.patch('/alerts/:id/status', requireAuth, alertController.updateStatus);

// Facilities
router.get('/facilities', requireAuth, facilityController.list);
router.get('/facilities/nearby', requireAuth, facilityController.nearby);
router.post('/facilities', requireAuth, requireRole('admin'), facilityController.create);
router.patch('/facilities/:id', requireAuth, requireRole('admin'), facilityController.update);

// Uploads (Cloudinary)
router.post('/uploads', requireAuth, upload.single('file'), uploadController.upload);

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
router.post('/assistant/chat', requireAuth, assistantController.chat);
router.post('/assistant/speak', requireAuth, assistantController.speak);
router.post('/assistant/checkin-questions', requireAuth, assistantController.checkinQuestions);
router.post('/assistant/diet-plan', requireAuth, assistantController.dietPlan);
router.post('/assistant/daily-tips', requireAuth, assistantController.dailyTips);

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
