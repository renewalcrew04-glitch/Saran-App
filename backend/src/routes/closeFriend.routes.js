import express from "express";
import { addCloseFriend, listCloseFriends, removeCloseFriend } from "../controllers/closeFriend.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/", protect, listCloseFriends);
router.post("/:uid", protect, addCloseFriend);
router.delete("/:uid", protect, removeCloseFriend);

export default router;
