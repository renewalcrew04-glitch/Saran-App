import User from "../models/User.model.js";

export const updateMessagingSettings = async (req, res, next) => {
  try {
    const { dmSettings, commentSettings } = req.body;

    const allowedDM = ["everyone", "followers", "no_one"];
    const allowedComments = ["everyone", "followers", "no_one"];

    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    if (dmSettings && !allowedDM.includes(dmSettings)) {
      return res.status(400).json({ success: false, message: "Invalid dmSettings" });
    }

    if (commentSettings && !allowedComments.includes(commentSettings)) {
      return res.status(400).json({ success: false, message: "Invalid commentSettings" });
    }

    if (dmSettings) user.dmSettings = dmSettings;
    if (commentSettings) user.commentSettings = commentSettings;

    await user.save();

    return res.json({
      success: true,
      message: "Settings updated",
      settings: {
        dmSettings: user.dmSettings,
        commentSettings: user.commentSettings,
      },
    });
  } catch (err) {
    next(err);
  }
};
