import express from 'express';
import {
  getUserProfile,
  updateUserProfile,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing,
  searchUsers
} from '../controllers/user.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.get('/:uid', protect, getUserProfile);
router.put('/:uid', protect, updateUserProfile);
router.post('/:uid/follow', protect, followUser);
router.delete('/:uid/follow', protect, unfollowUser);
router.get('/:uid/followers', protect, getFollowers);
router.get('/:uid/following', protect, getFollowing);
router.get('/search', protect, searchUsers);

export default router;
