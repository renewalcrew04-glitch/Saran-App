import express from 'express';
import {
  deleteMyAccount,
  followUser,
  getFollowers,
  getFollowing,
  getUserPosts,
  getUserProfile,
  searchUsers,
  unfollowUser,
  updateUserProfile,
} from '../controllers/user.controller.js';

import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// IMPORTANT: Specific routes (like /search) must come BEFORE parameterized routes (like /:uid)
router.get('/search', protect, searchUsers);

// ✅ keep ME routes here
router.delete('/me/delete', protect, deleteMyAccount);
router.delete('/me', protect, deleteMyAccount);

// then parameter routes
router.get('/:uid', protect, getUserProfile);
router.put('/:uid', protect, updateUserProfile);
router.post('/:uid/follow', protect, followUser);
router.delete('/:uid/follow', protect, unfollowUser);
router.get('/:uid/followers', protect, getFollowers);
router.get('/:uid/following', protect, getFollowing);
router.get('/:uid/posts', protect, getUserPosts); // ✅ NOW WORKS

export default router;
