import CloseFriend from "../models/CloseFriend.model.js";
import User from "../models/User.model.js";

export const addCloseFriend = async (req, res, next) => {
  try {
    const ownerId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) return res.status(404).json({ success: false, message: "User not found" });

    await CloseFriend.findOneAndUpdate(
      { owner: ownerId, friend: target._id },
      { owner: ownerId, friend: target._id },
      { upsert: true, new: true }
    );

    res.json({ success: true, message: "Added to close friends" });
  } catch (err) {
    next(err);
  }
};

export const removeCloseFriend = async (req, res, next) => {
  try {
    const ownerId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) return res.status(404).json({ success: false, message: "User not found" });

    await CloseFriend.deleteOne({ owner: ownerId, friend: target._id });

    res.json({ success: true, message: "Removed from close friends" });
  } catch (err) {
    next(err);
  }
};

export const listCloseFriends = async (req, res, next) => {
  try {
    const ownerId = req.user._id;

    const list = await CloseFriend.find({ owner: ownerId })
      .populate("friend", "uid username name avatar verified")
      .sort({ createdAt: -1 });

    res.json({ success: true, closeFriends: list.map(x => x.friend) });
  } catch (err) {
    next(err);
  }
};
