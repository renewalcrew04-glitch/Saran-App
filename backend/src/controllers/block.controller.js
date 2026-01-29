import Block from "../models/Block.model.js";
import User from "../models/User.model.js";

export const blockUser = async (req, res, next) => {
  try {
    const blockerId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    await Block.findOneAndUpdate(
      { blocker: blockerId, blocked: target._id },
      { blocker: blockerId, blocked: target._id },
      { upsert: true, new: true }
    );

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

    return res.json({
      success: true,
      blocked: blocked.map((b) => b.blocked),
    });
  } catch (err) {
    next(err);
  }
};
