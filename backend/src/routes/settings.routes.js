import express from "express";
import {
    getNotificationSettings,
    updateNotificationSettings,
} from "../controllers/notificationSettings.controller.js";
import { updateMessagingSettings } from "../controllers/settings.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.put("/messaging", protect, updateMessagingSettings);
router.get("/notifications", protect, getNotificationSettings);
router.put("/notifications", protect, updateNotificationSettings);

export default router;
