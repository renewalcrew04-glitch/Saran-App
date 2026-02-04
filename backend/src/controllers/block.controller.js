import Block from "../models/Block.model.js";
import Follow from "../models/Follow.model.js";
import User from "../models/User.model.js";

export const blockUser = async (req, res, next) => {
  try {
    const blockerId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    // Create block
    await Block.findOneAndUpdate(
      { blocker: blockerId, blocked: target._id },
      { blocker: blockerId, blocked: target._id },
      { upsert: true, new: true }
    );

    // Remove follow in both directions and update counts
    const followA = await Follow.findOneAndDelete({
      follower: blockerId,
      following: target._id,
    });
    if (followA && followA.status === "accepted") {
      await User.findByIdAndUpdate(target._id, { $inc: { followersCount: -1 } });
      await User.findByIdAndUpdate(blockerId, { $inc: { followingCount: -1 } });
    }

    const followB = await Follow.findOneAndDelete({
      follower: target._id,
      following: blockerId,
    });
    if (followB && followB.status === "accepted") {
      await User.findByIdAndUpdate(blockerId, { $inc: { followersCount: -1 } });
      await User.findByIdAndUpdate(target._id, { $inc: { followingCount: -1 } });
    }

    return res.json({ success: true, message: "User blocked" });
  } catch (err) {
    next(err);
  }
};

export const unblockUser = async (req, res, next) => {
  try {
    const blockerId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    await Block.deleteOne({ blocker: blockerId, blocked: target._id });

    return res.json({ success: true, message: "User unblocked" });
    } catch (err) {
      next(err);
    }
  };
  
  export const getBlockedUsers = async (req, res, next) => {
  try {
    const blockerId = req.user._id;

    const blocked = await Block.find({ blocker: blockerId })
      .populate("blocked", "uid username name avatar verified")
      .sort({ createdAt: -1 });

    const list = blocked
      .map((b) => b.blocked)
      .filter(Boolean)
      .map((u) => (u && typeof u.toObject === 'function' ? u.toObject() : u));
    return res.json({
      success: true,
      blocked: list,
    });
  } catch (err) {
    next(err);
  }
};
