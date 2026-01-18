import express from 'express';
import {
  createPost,
  getPost,
  updatePost,
  deletePost,
  likePost,
  unlikePost,
  repost,
  quotePost,
  getComments,
  addComment
} from '../controllers/post.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.post('/', protect, createPost);
router.get('/:id', protect, getPost);
router.put('/:id', protect, updatePost);
router.delete('/:id', protect, deletePost);
router.post('/:id/like', protect, likePost);
router.delete('/:id/like', protect, unlikePost);
router.post('/:id/repost', protect, repost);
router.post('/:id/quote', protect, quotePost);
router.get('/:id/comments', protect, getComments);
router.post('/:id/comments', protect, addComment);

export default router;
