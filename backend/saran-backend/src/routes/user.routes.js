import express from 'express';
import {
  acceptFollowRequest,
  declineFollowRequest,
  deleteMyAccount,
  followUser,
  getFollowers,
  getFollowing,
  getMyFollowRequests,
  getMyPendingFollowing,
  getSuggestions,
  getUserPosts,
  getUserProfile,
  searchUsers,
  setMeGender,
  unfollowUser,
  updateMe,
  updateUserProfile,
} from '../controllers/user.controller.js';

import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// IMPORTANT: Specific routes (like /search, /suggestions, /me) must come BEFORE parameterized routes (like /:uid)
router.get('/search', protect, searchUsers);
router.get('/suggestions', protect, getSuggestions);

// ✅ ME routes (update profile / avatar / cover)
router.put('/me', protect, updateMe);
router.patch('/me/gender', protect, setMeGender);
router.get('/me/follow-requests', protect, getMyFollowRequests);
router.get('/me/pending-following', protect, getMyPendingFollowing);
router.delete('/me/delete', protect, deleteMyAccount);
router.delete('/me', protect, deleteMyAccount);

// then parameter routes
router.get('/:uid', protect, getUserProfile);
router.put('/:uid', protect, updateUserProfile);
router.post('/:uid/follow', protect, followUser);
router.delete('/:uid/follow', protect, unfollowUser);
router.post('/:uid/follow-request/accept', protect, acceptFollowRequest);
router.post('/:uid/follow-request/decline', protect, declineFollowRequest);
router.get('/:uid/followers', protect, getFollowers);
router.get('/:uid/following', protect, getFollowing);
router.get('/:uid/posts', protect, getUserPosts); // ✅ NOW WORKS

export default router;
