import express from "express";
import { uploadSingle } from "../controllers/upload.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

// Health check: GET /api/upload/check (confirms router is mounted)
router.get("/check", (_, res) => res.json({ ok: true, route: "upload" }));

router.post("/single", protect, ...uploadSingle);

export default router;
