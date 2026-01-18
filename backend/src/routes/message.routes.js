import express from 'express';
import {
  getConversations,
  getConversation,
  sendMessage,
  markAsRead,
  deleteConversation
} from '../controllers/message.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

router.get('/', protect, getConversations);
router.get('/:conversationId', protect, getConversation);
router.post('/:conversationId/messages', protect, sendMessage);
router.put('/:conversationId/read', protect, markAsRead);
router.delete('/:conversationId', protect, deleteConversation);

export default router;
