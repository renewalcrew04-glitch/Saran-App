import express from "express";
import {
    getMutedContent,
    updateMutedContent,
} from "../controllers/content_mute.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/", protect, getMutedContent);
router.put("/", protect, updateMutedContent);

export default router;
