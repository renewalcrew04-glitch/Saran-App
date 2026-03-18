import express from "express";
import {
    createCollection,
    getCollections,
    toggleSavePost,
} from "../controllers/save.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.post("/:postId", protect, toggleSavePost);
router.post("/collection/create", protect, createCollection);
router.get("/collections", protect, getCollections);

export default router;
