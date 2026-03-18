import User from "../models/User.model.js";

/**
 * GET /settings/notifications
 */
export const getNotificationSettings = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id)
      .select("notificationSettings");

    if (!user) {
      return res.status(404).json({ success: false });
    }

    return res.json({
      success: true,
      notificationSettings: user.notificationSettings,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /settings/notifications
 */
export const updateNotificationSettings = async (req, res, next) => {
  try {
    const updates = req.body;

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false });
    }

    user.notificationSettings = {
      ...user.notificationSettings,
      ...updates,
    };

    await user.save();

    return res.json({
      success: true,
      notificationSettings: user.notificationSettings,
    });
  } catch (err) {
    next(err);
  }
};
