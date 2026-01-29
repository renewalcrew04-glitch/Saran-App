import express from "express";
import {
    getPostsByHashtag,
    getTrendingHashtags,
} from "../controllers/hashtag.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/trending", protect, getTrendingHashtags);
router.get("/:tag", protect, getPostsByHashtag);

export default router;
