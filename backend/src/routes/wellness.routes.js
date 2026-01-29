import express from 'express';
import {
  getWellnessStats,
  getWellnessStreak,
  updateWellnessActivity
} from '../controllers/wellness.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import scycleRoutes from "./scycle.routes.js";

const router = express.Router();

router.get('/streak', protect, getWellnessStreak);
router.post('/activity', protect, updateWellnessActivity);
router.get('/stats', protect, getWellnessStats);
router.use("/s-cycle", scycleRoutes);


export default router;
