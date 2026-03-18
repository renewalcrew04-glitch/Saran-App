import Notification from "../models/Notification.model.js";
import User from "../models/User.model.js";
import { sendNotificationPush } from "./push.service.js";

/**
 * Map notification type to push message
 */
const getPushText = (type) => {
  switch (type) {
    case "like":
      return "Someone liked your post";
    case "comment":
      return "New comment on your post";
    case "reply":
      return "Someone replied to your comment";
    case "repost":
      return "Your post was reposted";
    case "quote":
      return "Your post was quoted";
    case "follow":
      return "Someone started following you";
    case "follow_request":
      return "Someone requested to follow you";
    case "follow_accept":
      return "Your follow request was accepted";
    case "space_join":
      return "Someone joined your Space";
    case "space_reminder":
      return "Your Space is starting soon";
    case "mention":
      return "Someone mentioned you in a post";
    case "sos_close":
      return "SOS from a close friend";
    case "sos_nearby":
      return "Emergency SOS nearby";
    case "sos_accept":
      return "Someone is on their way to help";
    case "sos_resolve":
      return "SOS has been resolved";
    case "wellness":
      return "Time for your daily wellness check-in";
    case "sdaily":
      return "You have a new daily update";
    case "sframe_view":
      return "Someone viewed your SFrame";
    case "moderation":
      return "A moderation action was taken on your content";
    case "verification":
      return "Your verification status has been updated";
    default:
      return "You have a new notification";
  }
};

/**
 * Central notification creator
 * - Respects user preferences
 * - Stores in DB
 * - Sends AWS SNS push
 */
export const createNotification = async ({
  userId,
  actorId = null,
  type,
  entityId = null,
  entityType = null,
  meta = {},
}) => {
  const user = await User.findById(userId).select(
    "notificationSettings awsPushEndpointArn"
  );

  if (!user) return;

  const prefs = user.notificationSettings || {};

  // Respect preferences (SOS & moderation handled elsewhere if needed)
  const blocked =
    (type === "like" && prefs.likes === false) ||
    (type === "comment" && prefs.comments === false) ||
    (type === "reply" && prefs.comments === false) ||
    (type === "repost" && prefs.reposts === false) ||
    (type === "quote" && prefs.reposts === false) ||
    ((type === "follow" || type === "follow_request" || type === "follow_accept") && prefs.follows === false) ||
    (type === "mention" && prefs.mentions === false) ||
    (type.startsWith("space_") && prefs.spaces === false) ||
    ((type === "sos_close") && prefs.sosCloseFriends === false) ||
    ((type === "sos_nearby") && prefs.sosNearby === false);

  if (blocked) return;

  // 1️⃣ Store notification in DB
  await Notification.create({
    userId,
    actorId,
    type,
    entityId,
    entityType,
    meta,
  });

  // 2️⃣ Send push notification (AWS SNS)
  if (user.awsPushEndpointArn) {
    await sendNotificationPush({
      userId,
      title: "New activity",
      body: getPushText(type),
      data: {
        type,
        entityId: entityId ? entityId.toString() : "",
      },
    });
  }
};
