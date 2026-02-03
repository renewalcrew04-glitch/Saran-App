import express from 'express';
import {
  createSFrame,
  getSFrames,
  getSFrame,
  deleteSFrame,
  viewSFrame,
  replyToSFrame
} from '../controllers/sframe.controller.js';
import { uploadSingle } from '../controllers/upload.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// Route for uploading story media
router.post('/upload', protect, uploadSingle);

// Standard S-Frame routes
router.post('/', protect, createSFrame);
router.get('/', protect, getSFrames);
router.get('/:id', protect, getSFrame);
router.delete('/:id', protect, deleteSFrame);
router.post('/:id/view', protect, viewSFrame);
router.post('/:id/reply', protect, replyToSFrame);

export default router;