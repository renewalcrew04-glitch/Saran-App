import express from "express";
import {
    getNotificationSettings,
    updateNotificationSettings,
} from "../controllers/notificationSettings.controller.js";
import { getMessagingSettings, updateMessagingSettings } from "../controllers/settings.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/messaging", protect, getMessagingSettings);
router.put("/messaging", protect, updateMessagingSettings);
router.get("/notifications", protect, getNotificationSettings);
router.put("/notifications", protect, updateNotificationSettings);

export default router;
