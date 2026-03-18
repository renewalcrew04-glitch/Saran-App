import express from "express";
import { blockUser, getBlockedUsers, unblockUser } from "../controllers/block.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.post("/:uid", protect, blockUser);
router.delete("/:uid", protect, unblockUser);
router.get("/", protect, getBlockedUsers);

export default router;
