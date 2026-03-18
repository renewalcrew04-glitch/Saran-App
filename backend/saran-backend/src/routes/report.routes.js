import express from "express";
import { reportPost, reportUser } from "../controllers/report.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.post("/post/:postId", protect, reportPost);
router.post("/user/:uid", protect, reportUser);

export default router;
