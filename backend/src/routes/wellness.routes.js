import express from 'express';
import {
  getWellnessStreak,
  updateWellnessActivity,
  getWellnessStats
} from '../controllers/wellness.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.get('/streak', protect, getWellnessStreak);
router.post('/activity', protect, updateWellnessActivity);
router.get('/stats', protect, getWellnessStats);

export default router;
