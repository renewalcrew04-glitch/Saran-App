import express from 'express';
import {
  createEvent,
  getEvent,
  updateEvent,
  deleteEvent,
  getEvents,
  attendEvent,
  unattendEvent
} from '../controllers/event.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.post('/', protect, createEvent);
router.get('/', protect, getEvents);
router.get('/:id', protect, getEvent);
router.put('/:id', protect, updateEvent);
router.delete('/:id', protect, deleteEvent);
router.post('/:id/attend', protect, attendEvent);
router.delete('/:id/attend', protect, unattendEvent);

export default router;
