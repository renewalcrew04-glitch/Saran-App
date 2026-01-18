import express from 'express';
import {
  getHomeFeed,
  getUserFeed,
  getExploreFeed
} from '../controllers/feed.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.get('/home', protect, getHomeFeed);
router.get('/user/:uid', protect, getUserFeed);
router.get('/explore', protect, getExploreFeed);

export default router;
