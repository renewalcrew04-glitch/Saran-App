import mongoose from "mongoose";
import Block from "../models/Block.model.js";
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
      echoes: [],
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
 * Returns stories from the current user and from users they follow (accepted only).
 * So: when someone follows you, they see YOUR stories in their feed (because they follow you).
 */
export const getSFrames = async (req, res) => {
  try {
    const now = new Date();

    // People I follow (accepted): follower = me, following = them
    const followingDocs = await Follow.find({
      follower: req.user._id,
      status: "accepted",
    })
      .select("following")
      .lean();

    const followingIds = followingDocs.map((f) => f.following).filter(Boolean);
    // Normalize to ObjectIds so the query always matches
    const selfId = mongoose.Types.ObjectId.isValid(req.user._id)
      ? new mongoose.Types.ObjectId(req.user._id)
      : req.user._id;
    let allowedUserIds = [
      selfId,
      ...followingIds.map((id) =>
        mongoose.Types.ObjectId.isValid(id) ? new mongoose.Types.ObjectId(id) : id
      ),
    ].filter(Boolean);

    // Exclude blocked users: viewer blocked them or they blocked viewer (no stories from them)
    const asBlocker = await Block.find({ blocker: req.user._id }).select("blocked").lean();
    const asBlocked = await Block.find({ blocked: req.user._id }).select("blocker").lean();
    const blockedIds = new Set([
      ...asBlocker.map((b) => b.blocked.toString()),
      ...asBlocked.map((b) => b.blocker.toString()),
    ]);
    if (blockedIds.size > 0) {
      const blockedObjectIds = [...blockedIds]
        .filter((id) => mongoose.Types.ObjectId.isValid(id))
        .map((id) => new mongoose.Types.ObjectId(id));
      allowedUserIds = allowedUserIds.filter(
        (id) => !blockedObjectIds.some((bid) => bid.equals(id))
      );
    }

    const frames = await SFrame.find({
      uid: { $in: allowedUserIds },
      expiresAt: { $gt: now },
    })
      .sort({ createdAt: -1 })
      .lean();

    // Debug: see why stories might not show for followers (check PM2 logs)
    console.log(
      "[getSFrames] viewerId=%s followingCount=%d allowedCount=%d framesCount=%d",
      req.user._id?.toString(),
      followingIds.length,
      allowedUserIds.length,
      frames.length
    );

    const ownerIds = [...new Set(frames.map((f) => f.uid.toString()))];
    const owners = await User.find({ _id: { $in: ownerIds } })
      .select('name avatar username')
      .lean();
    const ownerMap = Object.fromEntries(
      owners.map((o) => [o._id.toString(), { name: o.name, avatar: o.avatar, username: o.username }])
    );
    const framesWithOwner = frames.map((f) => ({
      ...f,
      ownerName: ownerMap[f.uid.toString()]?.name,
      ownerAvatar: ownerMap[f.uid.toString()]?.avatar,
      ownerUsername: ownerMap[f.uid.toString()]?.username,
    }));

    return res.json(framesWithOwner);
  } catch (err) {
    console.error("getSFrames error:", err);
    return res.status(500).json({ message: "Failed to load S-Frames" });
  }
};

/**
 * GET SINGLE S-FRAME
 * GET /api/sframes/:id
 * Blocked users cannot view each other's stories.
 */
export const getSFrame = async (req, res) => {
  try {
    const frame = await SFrame.findById(req.params.id).lean();
    if (!frame) {
      return res.status(404).json({ message: "S-Frame not found" });
    }

    const viewerId = req.user._id;
    const ownerId = frame.uid;
    const blockRelation = await Block.findOne({
      $or: [
        { blocker: viewerId, blocked: ownerId },
        { blocker: ownerId, blocked: viewerId },
      ],
    });
    if (blockRelation) {
      return res.status(403).json({ message: "Cannot view this story" });
    }

    const [owner, viewers] = await Promise.all([
      User.findById(frame.uid).select("name avatar username").lean(),
      User.find({ _id: { $in: frame.views || [] } }, { name: 1, avatar: 1, photoURL: 1 }).lean(),
    ]);
    const viewersWithAvatar = viewers.map((v) => ({
      ...v,
      photoURL: v.photoURL || v.avatar,
    }));
    const echoIds = (frame.echoes || []).map((e) => e.toString());

    return res.json({
      ...frame,
      ownerName: owner?.name,
      ownerAvatar: owner?.avatar,
      ownerUsername: owner?.username,
      views: viewersWithAvatar,
      echoes: echoIds,
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
 * SEND ECHO (HEART) ON S-FRAME
 * POST /api/sframes/:id/echo
 * Adds the viewer to frame.echoes so owner sees a heart next to them in "Who viewed".
 */
export const echoSFrame = async (req, res) => {
  try {
    const frame = await SFrame.findById(req.params.id);
    if (!frame) {
      return res.status(404).json({ message: "S-Frame not found" });
    }

    const viewerId = req.user._id;
    const ownerId = frame.uid;

    if (viewerId.toString() === ownerId.toString()) {
      return res.status(400).json({ message: "Cannot echo your own story" });
    }

    const alreadyEchoed = (frame.echoes || [])
      .map((e) => e.toString())
      .includes(viewerId.toString());

    if (!alreadyEchoed) {
      await SFrame.updateOne(
        { _id: frame._id },
        { $addToSet: { echoes: viewerId } },
      );
      await Notification.create({
        userId: frame.uid,
        actorId: viewerId,
        type: "sframe_echo",
        entityId: frame._id,
        entityType: "user",
      });
    }

    return res.json({ success: true });
  } catch (err) {
    console.error("echoSFrame error:", err);
    return res.status(500).json({ message: "Failed to send echo" });
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
