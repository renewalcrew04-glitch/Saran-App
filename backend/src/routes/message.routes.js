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

// ✅ Static routes FIRST (before /:conversationId to avoid wrong matching)
router.post("/dm", protect, getOrCreateConversation);
router.get("/search-users", protect, searchUsersForDm);

// Conversations
router.get("/", protect, getConversations);
router.get("/:conversationId", protect, getConversation);
router.post("/:conversationId/messages", protect, sendMessage);
router.put("/:conversationId/read", protect, markAsRead);
router.put("/:conversationId/typing", protect, setTyping);
router.put("/:conversationId/messages/:messageId/reaction", protect, reactToMessage);
router.put("/:conversationId", protect, updateConversationFlags);
router.delete("/:conversationId", protect, deleteConversation);

export default router;
