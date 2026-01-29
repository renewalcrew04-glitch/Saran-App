import express from 'express';
import {
  createSFrame,
  getSFrames,      // ✅ Corrected Name (was getActiveSFrames)
  viewSFrame,      // ✅ Corrected Name (was markViewed)
  replyToSFrame
} from '../controllers/sframe.controller.js';
import { uploadSingle } from '../controllers/upload.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// Route for uploading story media
router.post('/upload', protect, uploadSingle);

// Standard S-Frame routes
router.post('/', protect, createSFrame);
router.get('/', protect, getSFrames);       // ✅ Matches controller
router.post('/:id/view', protect, viewSFrame); // ✅ Matches controller
router.post('/:id/reply', protect, replyToSFrame);

export default router;