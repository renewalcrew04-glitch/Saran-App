const express = require("express");
const router = express.Router();

const MindJournal = require("../models/MindJournal");

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

// ✅ GET: Get All Journals by userId
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const journals = await MindJournal.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json(
      journals.map((j) => ({
        _id: j._id,
        userId: j.userId,
        presentFeel: j.presentFeel,
        stopComparison: j.stopComparison,
        selfCare: j.selfCare,
        createdAt: j.createdAt,
      }))
    );
  } catch (err) {
    console.error("Mind Journal Fetch Error:", err);
    return res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
