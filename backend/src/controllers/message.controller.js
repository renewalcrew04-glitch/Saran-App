import mongoose from "mongoose";
import Conversation from "../models/Conversation.model.js";
import Message from "../models/Message.model.js";
import User from "../models/User.model.js";

// Helpers
const mapKey = (id) => id.toString();

// ============================
// GET /api/messages
// Return all conversations for logged in user
// ============================
export const getConversations = async (req, res, next) => {
  try {
    const myId = req.user._id;

    const convos = await Conversation.find({
      participants: myId,
    })
      .sort({ lastMessageAt: -1 })
      .lean();

    // build response with otherUser
    const result = [];
    for (const c of convos) {
      const otherId = (c.participants || []).find(
        (p) => p.toString() !== myId.toString()
      );

      let otherUser = null;
      if (otherId) {
        const u = await User.findById(otherId).lean();
        if (u) {
          otherUser = {
            _id: u._id.toString(),
            uid: u._id.toString(),
            name: u.name || u.username || "User",
            username: u.username || "",
            avatar: u.avatar || null,
            online: u.online === true,
          };
        }
      }

      const unreadMap = c.unread || {};
      const unreadCount =
        unreadMap instanceof Map
          ? unreadMap.get(mapKey(myId)) || 0
          : unreadMap?.[mapKey(myId)] || 0;

      const pinnedMap = c.pinned || {};
      const mutedMap = c.muted || {};
      const archivedMap = c.archived || {};

      const isPinned =
        pinnedMap instanceof Map
          ? pinnedMap.get(mapKey(myId)) === true
          : pinnedMap?.[mapKey(myId)] === true;

      const isMuted =
        mutedMap instanceof Map
          ? mutedMap.get(mapKey(myId)) === true
          : mutedMap?.[mapKey(myId)] === true;

      const isArchived =
        archivedMap instanceof Map
          ? archivedMap.get(mapKey(myId)) === true
          : archivedMap?.[mapKey(myId)] === true;

      result.push({
        _id: c._id.toString(),
        participants: (c.participants || []).map((x) => x.toString()),
        lastMessage: c.lastMessage || "",
        lastMessageAt: c.lastMessageAt || c.updatedAt || new Date(),
        unreadCount: unreadCount,
        isPinned,
        isMuted,
        isArchived,
        otherUser,
      });
    }

    return res.json({
      success: true,
      conversations: result,
    });
  } catch (error) {
    next(error);
  }
};

// ============================
// GET /api/messages/:conversationId
// Return conversation + messages
// ============================
export const getConversation = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const { conversationId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(conversationId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid conversationId",
      });
    }

    const convo = await Conversation.findById(conversationId).lean();
    if (!convo) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    const isParticipant = (convo.participants || []).some(
      (p) => p.toString() === myId.toString()
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: "Not allowed",
      });
    }

    const messages = await Message.find({ conversationId })
      .sort({ createdAt: 1 })
      .lean();

    // typing map
    const typing = convo.typing || {};

    return res.json({
      success: true,
      conversation: {
        _id: convo._id.toString(),
        typing,
      },
      messages: messages.map((m) => ({
        _id: m._id.toString(),
        senderUid: m.senderUid.toString(),
        receiverUid: m.receiverUid.toString(),
        conversationId: m.conversationId.toString(),
        text: m.text,
        imageUrl: m.imageUrl,
        voiceUrl: m.voiceUrl,
        type: m.type,
        read: m.read === true,
        reactions: m.reactions || {},
        createdAt: m.createdAt,
      })),
    });
  } catch (error) {
    next(error);
  }
};

// ============================
// POST /api/messages/:conversationId/messages
// Send message (text/image/voice)
// ============================
export const sendMessage = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const { conversationId } = req.params;
    const { receiverUid, type, text, imageUrl, voiceUrl } = req.body;

    if (!mongoose.Types.ObjectId.isValid(conversationId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid conversationId",
      });
    }

    if (!receiverUid || !mongoose.Types.ObjectId.isValid(receiverUid)) {
      return res.status(400).json({
        success: false,
        message: "Invalid receiverUid",
      });
    }

    const convo = await Conversation.findById(conversationId);
    if (!convo) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    const isParticipant = (convo.participants || []).some(
      (p) => p.toString() === myId.toString()
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: "Not allowed",
      });
    }

    const msgType = type || "text";

    // validate message content
    if (msgType === "text" && (!text || text.trim().length === 0)) {
      return res.status(400).json({
        success: false,
        message: "Text is required",
      });
    }

    if (msgType === "image" && (!imageUrl || imageUrl.trim().length === 0)) {
      return res.status(400).json({
        success: false,
        message: "imageUrl is required",
      });
    }

    if (msgType === "voice" && (!voiceUrl || voiceUrl.trim().length === 0)) {
      return res.status(400).json({
        success: false,
        message: "voiceUrl is required",
      });
    }

    const message = await Message.create({
      senderUid: myId,
      receiverUid,
      conversationId,
      type: msgType,
      text: msgType === "text" ? text : null,
      imageUrl: msgType === "image" ? imageUrl : null,
      voiceUrl: msgType === "voice" ? voiceUrl : null,
      read: false,
      reactions: new Map(),
    });

    // update conversation last message
    convo.lastMessage =
      msgType === "text"
        ? text
        : msgType === "image"
        ? "📷 Photo"
        : "🎤 Voice";
    convo.lastMessageAt = new Date();

    // unread increment for receiver
    const currentUnread = convo.unread?.get(mapKey(receiverUid)) || 0;
    convo.unread.set(mapKey(receiverUid), currentUnread + 1);

    await convo.save();

    return res.json({
      success: true,
      message: {
        _id: message._id.toString(),
        senderUid: message.senderUid.toString(),
        receiverUid: message.receiverUid.toString(),
        conversationId: message.conversationId.toString(),
        text: message.text,
        imageUrl: message.imageUrl,
        voiceUrl: message.voiceUrl,
        type: message.type,
        read: message.read,
        reactions: message.reactions || {},
        createdAt: message.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ============================
// PUT /api/messages/:conversationId/read
// Mark conversation read (reset unread + mark messages read)
// ============================
export const markAsRead = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const { conversationId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(conversationId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid conversationId",
      });
    }

    const convo = await Conversation.findById(conversationId);
    if (!convo) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    convo.unread.set(mapKey(myId), 0);
    await convo.save();

    await Message.updateMany(
      {
        conversationId,
        receiverUid: myId,
        read: false,
      },
      { $set: { read: true } }
    );

    return res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

// ============================
// DELETE /api/messages/:conversationId
// Delete conversation + all messages (hard delete)
// ============================
export const deleteConversation = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const { conversationId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(conversationId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid conversationId",
      });
    }

    const convo = await Conversation.findById(conversationId);
    if (!convo) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    const isParticipant = (convo.participants || []).some(
      (p) => p.toString() === myId.toString()
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: "Not allowed",
      });
    }

    await Message.deleteMany({ conversationId });
    await Conversation.deleteOne({ _id: conversationId });

    return res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

// ============================
// PUT /api/messages/:conversationId
// body: { pinned?, muted?, archived? }
// ============================
export const updateConversationFlags = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const { conversationId } = req.params;
    const { pinned, muted, archived } = req.body;

    if (!mongoose.Types.ObjectId.isValid(conversationId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid conversationId",
      });
    }

    const convo = await Conversation.findById(conversationId);
    if (!convo) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    if (typeof pinned === "boolean") {
      convo.pinned.set(mapKey(myId), pinned);
    }
    if (typeof muted === "boolean") {
      convo.muted.set(mapKey(myId), muted);
    }
    if (typeof archived === "boolean") {
      convo.archived.set(mapKey(myId), archived);
    }

    await convo.save();

    return res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

// ============================
// PUT /api/messages/:conversationId/typing
// body: { value: true/false }
// ============================
export const setTyping = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const { conversationId } = req.params;
    const { value } = req.body;

    if (!mongoose.Types.ObjectId.isValid(conversationId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid conversationId",
      });
    }

    const convo = await Conversation.findById(conversationId);
    if (!convo) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    if (!convo.typing) convo.typing = {};
    convo.typing[mapKey(myId)] = value === true;

    await convo.save();

    return res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

// ============================
// PUT /api/messages/:conversationId/messages/:messageId/reaction
// body: { reaction: "❤️" | "😂" | "👍" | "😮" }
// ============================
export const reactToMessage = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const { conversationId, messageId } = req.params;
    const { reaction } = req.body;

    if (!mongoose.Types.ObjectId.isValid(conversationId)) {
      return res.status(400).json({ success: false, message: "Invalid conversationId" });
    }

    if (!mongoose.Types.ObjectId.isValid(messageId)) {
      return res.status(400).json({ success: false, message: "Invalid messageId" });
    }

    const allowed = ["❤️", "😂", "👍", "😮"];
    if (!allowed.includes(reaction)) {
      return res.status(400).json({
        success: false,
        message: "Invalid reaction",
      });
    }

    const msg = await Message.findOne({ _id: messageId, conversationId });
    if (!msg) {
      return res.status(404).json({ success: false, message: "Message not found" });
    }

    msg.reactions.set(mapKey(myId), reaction);
    await msg.save();

    return res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

// ============================
// POST /api/messages/dm
// body: { otherUid }
// ============================
export const getOrCreateConversation = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const { otherUid } = req.body;

    if (!otherUid || !mongoose.Types.ObjectId.isValid(otherUid)) {
      return res.status(400).json({
        success: false,
        message: "Invalid otherUid",
      });
    }

    if (myId.toString() === otherUid.toString()) {
      return res.status(400).json({
        success: false,
        message: "Cannot DM yourself",
      });
    }

    const otherUser = await User.findById(otherUid).lean();
    if (!otherUser) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    let convo = await Conversation.findOne({
      participants: { $all: [myId, otherUid] },
    });

    if (!convo) {
      convo = await Conversation.create({
        participants: [myId, otherUid],
        lastMessage: "",
        lastMessageAt: new Date(),
        unread: new Map([
          [mapKey(myId), 0],
          [mapKey(otherUid), 0],
        ]),
        pinned: new Map(),
        muted: new Map(),
        archived: new Map(),
        typing: {},
      });
    }

    return res.json({
      success: true,
      conversationId: convo._id.toString(),
      otherUser: {
        uid: otherUser._id.toString(),
        _id: otherUser._id.toString(),
        name: otherUser.name || otherUser.username || "User",
        username: otherUser.username || "",
        avatar: otherUser.avatar || null,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ============================
// GET /api/messages/search-users?q=...
// ============================
export const searchUsersForDm = async (req, res, next) => {
  try {
    const myId = req.user._id;
    const q = (req.query.q || "").toString().trim();

    if (!q || q.length < 1) {
      return res.json({ success: true, users: [] });
    }

    const users = await User.find(
      {
        _id: { $ne: myId },
        $or: [
          { name: { $regex: q, $options: "i" } },
          { username: { $regex: q, $options: "i" } },
        ],
      },
      { password: 0 }
    )
      .limit(20)
      .lean();

    return res.json({
      success: true,
      users: users.map((u) => ({
        uid: u._id.toString(),
        _id: u._id.toString(),
        name: u.name || u.username || "User",
        username: u.username || "",
        avatar: u.avatar || null,
        online: u.online === true,
      })),
    });
  } catch (error) {
    next(error);
  }
};
