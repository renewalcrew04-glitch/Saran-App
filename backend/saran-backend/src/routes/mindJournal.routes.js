import express from "express";
import MindJournal from "../models/MindJournal.js";

const router = express.Router();

// ✅ POST: Save Journal
router.post("/", async (req, res) => {
  try {
    const { userId, presentFeel, stopComparison, selfCare } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    const journal = await MindJournal.create({
      userId,
      presentFeel: presentFeel || "",
      stopComparison: stopComparison || "",
      selfCare: selfCare || "",
    });

    return res.status(201).json({
      message: "Journal saved",
      journal,
    });
  } catch (err) {
    console.error("Mind Journal Save Error:", err);
    return res.status(500).json({ message: "Server error" });
  }
});

// ✅ GET: Get Journals by userId
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const journals = await MindJournal.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json(journals);
  } catch (err) {
    console.error("Mind Journal Fetch Error:", err);
    return res.status(500).json({ message: "Server error" });
  }
});

// ✅ PUT: Update journal by id
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { presentFeel, stopComparison, selfCare } = req.body;

    const journal = await MindJournal.findByIdAndUpdate(
      id,
      {
        presentFeel: presentFeel ?? "",
        stopComparison: stopComparison ?? "",
        selfCare: selfCare ?? "",
      },
      { new: true }
    );

    if (!journal) {
      return res.status(404).json({ message: "Journal not found" });
    }

    return res.status(200).json({
      message: "Journal updated",
      journal,
    });
  } catch (err) {
    console.error("Mind Journal Update Error:", err);
    return res.status(500).json({ message: "Server error" });
  }
});

// ✅ DELETE: Delete journal by id
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const journal = await MindJournal.findByIdAndDelete(id);

    if (!journal) {
      return res.status(404).json({ message: "Journal not found" });
    }

    return res.status(200).json({ message: "Journal deleted" });
  } catch (err) {
    console.error("Mind Journal Delete Error:", err);
    return res.status(500).json({ message: "Server error" });
  }
});

export default router;
