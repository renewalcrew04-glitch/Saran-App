import express from "express";
import { uploadSingle } from "../controllers/upload.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.post("/single", protect, uploadSingle);

export default router;
