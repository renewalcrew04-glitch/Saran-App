import express from 'express';
import {
  register,
  login,
  getMe,
  updateProfile,
  logout,
  checkUsernameAvailability,
  getUsernameSuggestions,
  sendOtp,
  verifyOtp,
  validateStep1,
  validateStep2,
  validateStep3,
  verifySelfie,
  checkPasswordStrength,
} from '../controllers/auth.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// ── Username helpers ──────────────────────────────────────────────────────────
router.get('/username/check', checkUsernameAvailability);
router.post('/username/check', checkUsernameAvailability);
router.get('/username/suggestions', getUsernameSuggestions);
router.post('/username/suggestions', getUsernameSuggestions);

// ── Step-by-step signup validators ────────────────────────────────────────────
// Step 1: username + profile name
router.post('/validate/step1', validateStep1);
// Step 2: email + mobile + password
router.post('/validate/step2', validateStep2);
// Step 3: date of birth
router.post('/validate/step3', validateStep3);

// ── Selfie AI verification (Step 4) ───────────────────────────────────────────
router.post('/verify-selfie', verifySelfie);

// ── Password strength utility ─────────────────────────────────────────────────
router.get('/password-strength', checkPasswordStrength);
router.post('/password-strength', checkPasswordStrength);

// ── OTP (email verification) ──────────────────────────────────────────────────
router.post('/send-otp', sendOtp);
router.post('/verify-otp', verifyOtp);

// ── Core auth ─────────────────────────────────────────────────────────────────
router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.post('/logout', protect, logout);

export default router;
