import express from 'express';
import {
  register,
  login,
  getMe,
  updateProfile,
  logout,
  checkUsernameAvailability,
  getUsernameSuggestions,
} from '../controllers/auth.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.get('/username/check', checkUsernameAvailability);
router.get('/username/suggestions', getUsernameSuggestions);
router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.post('/logout', protect, logout);

export default router;
