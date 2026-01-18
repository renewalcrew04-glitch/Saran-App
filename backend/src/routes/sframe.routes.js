import express from 'express';
import {
  createSFrame,
  getSFrames,
  getSFrame,
  viewSFrame,
  echoSFrame
} from '../controllers/sframe.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.post('/', protect, createSFrame);
router.get('/', protect, getSFrames);
router.get('/:id', protect, getSFrame);
router.post('/:id/view', protect, viewSFrame);
router.post('/:id/echo', protect, echoSFrame);

export default router;
