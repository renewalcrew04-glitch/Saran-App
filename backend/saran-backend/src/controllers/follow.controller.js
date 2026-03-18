import Follow from "../models/Follow.model.js";
import User from "../models/User.model.js";

export const followUser = async (req, res, next) => {
  try {
    const followerId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) return res.status(404).json({ success: false, message: "User not found" });

    const status = target.isPrivate ? "pending" : "accepted";

    await Follow.findOneAndUpdate(
      { follower: followerId, following: target._id },
      { follower: followerId, following: target._id, status },
      { upsert: true, new: true }
    );

    return res.json({
      success: true,
      message: status === "pending" ? "Follow request sent" : "Followed",
      status,
    });
  } catch (err) {
    next(err);
  }
};

export const unfollowUser = async (req, res, next) => {
  try {
    const followerId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) return res.status(404).json({ success: false, message: "User not found" });

    await Follow.deleteOne({ follower: followerId, following: target._id });

    return res.json({ success: true, message: "Unfollowed" });
  } catch (err) {
    next(err);
  }
};
