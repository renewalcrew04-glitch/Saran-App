import express from "express";
import {
    getReminderStatus,
    updateReminderStatus,
} from "../controllers/eventReminder.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/:eventId", protect, getReminderStatus);
router.put("/:eventId", protect, updateReminderStatus);

export default router;
