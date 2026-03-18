import Notification from "../models/Notification.model.js";
import User from "../models/User.model.js";
import { registerDeviceToken } from "../utils/sns.js";

export const getNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({
      userId: req.user._id,
      deleted: false,
    })
      .populate('actorId', 'uid username name avatar')
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();

    const list = (notifications || []).map((n) => {
      const { actorId, ...rest } = n;
      return {
        ...rest,
        actor: actorId
          ? {
              uid: actorId.uid,
              username: actorId.username,
              name: actorId.name,
              avatar: actorId.avatar,
            }
          : null,
      };
    });

    res.json({ success: true, notifications: list });
  } catch (err) {
    next(err);
  }
};

export const getUnreadCount = async (req, res, next) => {
  try {
    const count = await Notification.countDocuments({
      userId: req.user._id,
      read: false,
      deleted: false,
    });
    res.json({ success: true, count });
  } catch (err) {
    next(err);
  }
};

export const registerDevice = async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ success: false, message: 'fcmToken is required' });
    }

    const endpointArn = await registerDeviceToken(fcmToken);

    await User.findByIdAndUpdate(req.user._id, { awsPushEndpointArn: endpointArn });

    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

export const markAsRead = async (req, res, next) => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { read: true }
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

export const markAllAsRead = async (req, res, next) => {
  try {
    await Notification.updateMany(
      { userId: req.user._id, read: false },
      { read: true }
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

export const deleteNotification = async (req, res, next) => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { deleted: true }
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};
