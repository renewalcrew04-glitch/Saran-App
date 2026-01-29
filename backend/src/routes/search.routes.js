import express from "express";
import {
  searchAll,
  searchPosts,
  searchUsers,
} from "../controllers/search.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/posts", protect, searchPosts);
router.get("/users", protect, searchUsers);
router.get("/all", protect, searchAll);

// ❌ removed because searchPeople is not defined
// router.get("/people", protect, searchPeople);

export default router;
