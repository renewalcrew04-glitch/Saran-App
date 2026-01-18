import express from 'express';
import {
  searchPosts,
  searchUsers,
  searchAll
} from '../controllers/search.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.get('/posts', protect, searchPosts);
router.get('/users', protect, searchUsers);
router.get('/all', protect, searchAll);

export default router;
