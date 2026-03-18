import Mute from "../models/Mute.model.js";
import User from "../models/User.model.js";

export const muteUser = async (req, res, next) => {
  try {
    const muterId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) return res.status(404).json({ success: false, message: "User not found" });

    await Mute.findOneAndUpdate(
      { muter: muterId, muted: target._id },
      { muter: muterId, muted: target._id },
      { upsert: true, new: true }
    );

    res.json({ success: true, message: "User muted" });
  } catch (err) {
    next(err);
  }
};

export const unmuteUser = async (req, res, next) => {
  try {
    const muterId = req.user._id;
    const { uid } = req.params;

    const target = await User.findOne({ uid });
    if (!target) return res.status(404).json({ success: false, message: "User not found" });

    await Mute.deleteOne({ muter: muterId, muted: target._id });

    res.json({ success: true, message: "User unmuted" });
  } catch (err) {
    next(err);
  }
};

export const listMuted = async (req, res, next) => {
  try {
    const muterId = req.user._id;

    const list = await Mute.find({ muter: muterId })
      .populate("muted", "uid username name avatar verified")
      .sort({ createdAt: -1 });

    res.json({ success: true, muted: list.map(x => x.muted) });
  } catch (err) {
    next(err);
  }
};
