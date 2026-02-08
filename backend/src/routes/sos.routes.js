import express from 'express';
import {
  createSOS,
  getSOS,
  updateSOSLocation,
  cancelSOS,
  resolveSOS
} from '../controllers/sos.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.post('/', protect, createSOS);
router.get('/:id', protect, getSOS);
router.put('/:id/location', protect, updateSOSLocation);
router.put('/:id/cancel', protect, cancelSOS);
router.put('/:id/resolve', protect, resolveSOS);

export default router;
