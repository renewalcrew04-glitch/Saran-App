import express from "express";
import {
    createEvent,
    updateEvent,
    getEvents,
    getEventById,
    joinEvent,
    getHostedEvents,
    getBookedEvents
} from "../controllers/space.controller.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

// Public/Feed
router.post("/events", protect, createEvent);
router.put("/events/:id", protect, updateEvent);
router.get("/events", protect, getEvents);
router.get("/events/:id", protect, getEventById);
router.post("/events/:id/join", protect, joinEvent);

// ✅ "My Events" Split Routes
router.get("/hosted-events", protect, getHostedEvents);
router.get("/booked-events", protect, getBookedEvents);

export default router;