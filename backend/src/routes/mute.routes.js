import express from "express";
import { listMuted, muteUser, unmuteUser } from "../controllers/mute.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/", protect, listMuted);
router.post("/:uid", protect, muteUser);
router.delete("/:uid", protect, unmuteUser);

export default router;
