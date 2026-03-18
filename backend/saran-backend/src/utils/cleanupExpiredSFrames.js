import SFrame from "../models/SFrame.model.js";

export const cleanupExpiredSFrames = async () => {
  const now = new Date();
  await SFrame.deleteMany({ expiresAt: { $lt: now } });
};
