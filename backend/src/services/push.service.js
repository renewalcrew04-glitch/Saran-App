import User from "../models/User.model.js";
import { sendPush } from "../utils/sns.js";

/**
 * Unified push sender using AWS SNS
 */
export const sendNotificationPush = async ({
  userId,
  title,
  body,
  data = {},
}) => {
  const user = await User.findById(userId)
    .select("awsPushEndpointArn notificationSettings");

  if (!user?.awsPushEndpointArn) return;

  await sendPush(user.awsPushEndpointArn, {
    title,
    body,
    data,
  });
};
