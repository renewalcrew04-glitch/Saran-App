import express from "express";
import {
    getHistory,
    getSummary,
    markPeriodStarted,
    saveDailyLog,
    updateLog,
    deleteLog,
} from "../controllers/scycle.controller.js";

const router = express.Router();

// Save mood + symptoms log
router.post("/log", saveDailyLog);

// Update log by id
router.put("/log/:id", updateLog);

// Delete log by id
router.delete("/log/:id", deleteLog);

// Period started today
router.post("/period-started", markPeriodStarted);

// History list
router.get("/history/:userId", getHistory);

// Summary for UI
router.get("/summary/:userId", getSummary);

export default router;
