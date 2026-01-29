import express from "express";
import {
  deleteConversation,
  getConversation,
  getConversations,
  getOrCreateConversation,
  markAsRead,
  reactToMessage,
  searchUsersForDm,
  sendMessage,
  setTyping,
  updateConversationFlags,
} from "../controllers/message.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

// ✅ Create or get DM conversation
router.post("/dm", protect, getOrCreateConversation);

// Conversations
router.get("/", protect, getConversations);
router.get("/:conversationId", protect, getConversation);
router.post("/:conversationId/messages", protect, sendMessage);
router.put("/:conversationId/read", protect, markAsRead);
router.delete("/:conversationId", protect, deleteConversation);
router.get("/search-users", protect, searchUsersForDm);

// Flags (pin/mute/archive)
router.put("/:conversationId", protect, updateConversationFlags);

// Typing
router.put("/:conversationId/typing", protect, setTyping);

// Reactions
router.put("/:conversationId/messages/:messageId/reaction", protect, reactToMessage);

export default router;
