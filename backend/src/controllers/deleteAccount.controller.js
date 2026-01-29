import Block from "../models/Block.model.js";
import CloseFriend from "../models/CloseFriend.model.js";
import Follow from "../models/Follow.model.js";
import Mute from "../models/Mute.model.js";
import User from "../models/User.model.js";

export const deleteMyAccount = async (req, res, next) => {
  try {
    const userId = req.user._id;

    // remove relations
    await Follow.deleteMany({ $or: [{ follower: userId }, { following: userId }] });
    await Block.deleteMany({ $or: [{ blocker: userId }, { blocked: userId }] });
    await Mute.deleteMany({ $or: [{ muter: userId }, { muted: userId }] });
    await CloseFriend.deleteMany({ $or: [{ owner: userId }, { friend: userId }] });

    // delete user
    await User.findByIdAndDelete(userId);

    return res.json({ success: true, message: "Account deleted successfully" });
  } catch (err) {
    next(err);
  }
};
