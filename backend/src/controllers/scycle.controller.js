import SCycleLog from "../models/scycleLog.model.js";

// helper: YYYY-MM-DD
const getDayKey = (date = new Date()) => {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
};

/**
 * POST /api/wellness/s-cycle/log
 * Save mood + symptoms (upsert = update if already logged today)
 */
export const saveDailyLog = async (req, res) => {
  try {
    const { userId, mood, symptoms, note } = req.body;

    if (!userId) return res.status(400).json({ message: "userId is required" });
    if (!mood) return res.status(400).json({ message: "mood is required" });

    const dayKey = getDayKey();

    const updated = await SCycleLog.findOneAndUpdate(
      { userId, dayKey },
      {
        $set: {
          mood,
          symptoms: Array.isArray(symptoms) ? symptoms : [],
          note: note || "",
          isPeriodStart: false,
          dayKey,
        },
      },
      { new: true, upsert: true }
    );

    return res.status(200).json({
      message: "Daily log saved",
      log: updated,
    });
  } catch (err) {
    console.error("saveDailyLog error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * POST /api/wellness/s-cycle/period-started
 * Marks period started today (also upserts for today)
 */
export const markPeriodStarted = async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) return res.status(400).json({ message: "userId is required" });

    const dayKey = getDayKey();

    const updated = await SCycleLog.findOneAndUpdate(
      { userId, dayKey },
      {
        $set: {
          mood: "period_started",
          symptoms: ["period_started"],
          note: "Period started",
          isPeriodStart: true,
          dayKey,
        },
      },
      { new: true, upsert: true }
    );

    return res.status(200).json({
      message: "Period started saved",
      log: updated,
    });
  } catch (err) {
    console.error("markPeriodStarted error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * PUT /api/wellness/s-cycle/log/:id
 * Update a log by id (mood, symptoms, note)
 */
export const updateLog = async (req, res) => {
  try {
    const { id } = req.params;
    const { mood, symptoms, note } = req.body;

    const log = await SCycleLog.findByIdAndUpdate(
      id,
      {
        mood: mood ?? "",
        symptoms: Array.isArray(symptoms) ? symptoms : [],
        note: note ?? "",
      },
      { new: true }
    );

    if (!log) {
      return res.status(404).json({ message: "Log not found" });
    }

    return res.status(200).json({
      message: "Log updated",
      log,
    });
  } catch (err) {
    console.error("updateLog error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * DELETE /api/wellness/s-cycle/log/:id
 * Delete a log by id
 */
export const deleteLog = async (req, res) => {
  try {
    const { id } = req.params;

    const log = await SCycleLog.findByIdAndDelete(id);

    if (!log) {
      return res.status(404).json({ message: "Log not found" });
    }

    return res.status(200).json({ message: "Log deleted" });
  } catch (err) {
    console.error("deleteLog error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * GET /api/wellness/s-cycle/history/:userId
 * Returns last 60 logs (latest first)
 */
export const getHistory = async (req, res) => {
  try {
    const { userId } = req.params;

    const logs = await SCycleLog.find({ userId })
      .sort({ createdAt: -1 })
      .limit(60);

    return res.status(200).json(logs);
  } catch (err) {
    console.error("getHistory error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * GET /api/wellness/s-cycle/summary/:userId
 * Basic cycle summary based on last period start
 */
export const getSummary = async (req, res) => {
  try {
    const { userId } = req.params;

    const cycleLength = 28;

    const lastPeriod = await SCycleLog.findOne({
      userId,
      isPeriodStart: true,
    }).sort({ createdAt: -1 });

    if (!lastPeriod) {
      return res.status(200).json({
        cycleLength,
        daysSincePeriodStart: null,
        daysUntilPeriod: cycleLength,
        lastPeriodStart: null,
        message: "No period start data yet",
      });
    }

    const now = new Date();
    const start = new Date(lastPeriod.createdAt);

    const diffDays = Math.floor(
      (now.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)
    );

    const daysUntilPeriod = Math.max(cycleLength - diffDays, 0);

    return res.status(200).json({
      cycleLength,
      lastPeriodStart: lastPeriod.createdAt,
      daysSincePeriodStart: diffDays,
      daysUntilPeriod,
      message: "Summary calculated",
    });
  } catch (err) {
    console.error("getSummary error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
