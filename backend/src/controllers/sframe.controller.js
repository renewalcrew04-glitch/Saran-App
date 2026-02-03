import Follow from "../models/Follow.model.js";
import Notification from "../models/Notification.model.js";
import SFrame from "../models/SFrame.model.js";
import SFrameReply from "../models/SFrameReply.model.js";
import User from "../models/User.model.js";

/**
 * CREATE S-FRAME
 * POST /api/sframes
 */
export const createSFrame = async (req, res) => {
  try {
    const {
      mediaType,
      mediaUrl = null,
      textContent = null,
      mood = null,
      durationHours = 24,
    } = req.body;

    if (!mediaType) {
      return res.status(400).json({ message: "mediaType is required" });
    }

    const expiresAt = new Date(
      Date.now() + durationHours * 60 * 60 * 1000
    );

    const frame = await SFrame.create({
      uid: req.user._id,
      mediaType,
      mediaUrl,
      textContent,
      mood,
      expiresAt,
      views: [],
    });

    return res.status(201).json(frame);
  } catch (err) {
    console.error("createSFrame error:", err);
    return res.status(500).json({ message: "Failed to create S-Frame" });
  }
};

/**
 * GET ACTIVE S-FRAMES (SELF + PEOPLE I FOLLOW) — Instagram-style
 * GET /api/sframes
 * Returns stories from the current user and from users they follow, so:
 * - When I share a story, I see it (my stories).
 * - Other users who follow me see my story in their feed.
 */
export const getSFrames = async (req, res) => {
  try {
    const now = new Date();

    // People I follow (Follow model uses follower / following)
    const followingDocs = await Follow.find({
      follower: req.user._id,
      status: "accepted",
    })
      .select("following")
      .lean();

    const followingIds = followingDocs.map((f) => f.following);
    const allowedUserIds = [req.user._id, ...followingIds]; // self + people I follow

    const frames = await SFrame.find({
      uid: { $in: allowedUserIds },
      expiresAt: { $gt: now },
    })
      .sort({ createdAt: -1 })
      .lean();

    return res.json(frames);
  } catch (err) {
    console.error("getSFrames error:", err);
    return res.status(500).json({ message: "Failed to load S-Frames" });
  }
};

/**
 * GET SINGLE S-FRAME
 * GET /api/sframes/:id
 */
export const getSFrame = async (req, res) => {
  try {
    const frame = await SFrame.findById(req.params.id).lean();
    if (!frame) {
      return res.status(404).json({ message: "S-Frame not found" });
    }

    // Populate viewers (name + photo)
    const viewers = await User.find(
      { _id: { $in: frame.views } },
      { name: 1, photoURL: 1 }
    );

    return res.json({
      ...frame,
      views: viewers,
    });
  } catch (err) {
    console.error("getSFrame error:", err);
    return res.status(500).json({ message: "Failed to load S-Frame" });
  }
};

/**
 * DELETE S-FRAME (owner only)
 * DELETE /api/sframes/:id
 */
export const deleteSFrame = async (req, res) => {
  try {
    const frame = await SFrame.findById(req.params.id);
    if (!frame) {
      return res.status(404).json({ message: "S-Frame not found" });
    }
    if (frame.uid.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not authorized to delete this story" });
    }
    await SFrameReply.deleteMany({ frameId: frame._id });
    await SFrame.deleteOne({ _id: frame._id });
    return res.status(204).send();
  } catch (err) {
    console.error("deleteSFrame error:", err);
    return res.status(500).json({ message: "Failed to delete S-Frame" });
  }
};

/**
 * MARK VIEW + NOTIFICATION
 * POST /api/sframes/:id/view
 */
export const viewSFrame = async (req, res) => {
  try {
    const frame = await SFrame.findById(req.params.id);
    if (!frame) {
      return res.status(404).json({ message: "S-Frame not found" });
    }

    const viewerId = req.user._id.toString();
    const ownerId = frame.uid.toString();

    const alreadyViewed = frame.views
      .map((v) => v.toString())
      .includes(viewerId);

    await SFrame.updateOne(
      { _id: frame._id },
      { $addToSet: { views: req.user._id } }
    );

    // 🔔 Notify only once, not self
    if (!alreadyViewed && viewerId !== ownerId) {
      await Notification.create({
        userId: frame.uid,
        actorId: req.user._id,
        type: "sframe_view",
        entityId: frame._id,
        entityType: "user",
      });
    }

    return res.json({ success: true });
  } catch (err) {
    console.error("viewSFrame error:", err);
    return res.status(500).json({ message: "Failed to mark view" });
  }
};

/**
 * REPLY TO S-FRAME + NOTIFICATION
 * POST /api/sframes/:id/reply
 */
export const replyToSFrame = async (req, res) => {
  try {
    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({ message: "Reply text required" });
    }

    const frame = await SFrame.findById(req.params.id);
    if (!frame) {
      return res.status(404).json({ message: "S-Frame not found" });
    }

    const reply = await SFrameReply.create({
      frameId: frame._id,
      fromUid: req.user._id,
      toUid: frame.uid,
      text: text.trim(),
    });

    // 🔔 notify owner
    if (String(frame.uid) !== String(req.user._id)) {
      await Notification.create({
        userId: frame.uid,
        actorId: req.user._id,
        type: "sframe_reply",
        entityId: frame._id,
        entityType: "user",
      });
    }

    return res.status(201).json(reply);
  } catch (err) {
    console.error("replyToSFrame error:", err);
    return res.status(500).json({ message: "Failed to reply to S-Frame" });
  }
};

/**
 * GET REPLIES (OWNER ONLY)
 * GET /api/sframes/:id/replies
 */
export const getSFrameReplies = async (req, res) => {
  try {
    const frame = await SFrame.findById(req.params.id);
    if (!frame) {
      return res.status(404).json({ message: "S-Frame not found" });
    }

    // 🔒 only owner can read replies
    if (String(frame.uid) !== String(req.user._id)) {
      return res.status(403).json({ message: "Not authorized" });
    }

    const replies = await SFrameReply.find({
      frameId: frame._id,
    })
      .populate("fromUid", "name photoURL")
      .sort({ createdAt: -1 });

    return res.json(replies);
  } catch (err) {
    console.error("getSFrameReplies error:", err);
    return res.status(500).json({ message: "Failed to load replies" });
  }
};
