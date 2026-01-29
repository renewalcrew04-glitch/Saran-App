import express from "express";
import {
    createEvent,
    getEvents,
    getEventById,
    joinEvent,
    getHostedEvents, // ✅ New Name (for Hosted tab)
    getBookedEvents  // ✅ New Name (for Booked tab)
} from "../controllers/space.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

// Public/Feed
router.post("/events", protect, createEvent);
router.get("/events", protect, getEvents);
router.get("/events/:id", protect, getEventById);
router.post("/events/:id/join", protect, joinEvent);

// ✅ "My Events" Split Routes
router.get("/hosted-events", protect, getHostedEvents);
router.get("/booked-events", protect, getBookedEvents);

export default router;