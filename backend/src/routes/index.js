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

// Facility dashboard
router.get(
  '/dashboard/catchment',
  requireAuth,
  requireRole('facility', 'admin'),
  dashboardController.catchment
);

module.exports = router;
