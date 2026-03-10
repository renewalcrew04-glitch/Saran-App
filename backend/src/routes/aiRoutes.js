import express from "express";
import { protect } from "../middleware/auth.middleware.js";
import { askAI } from "../services/aiService.js";

const router = express.Router();

router.post("/chat", protect, async (req, res) => {

  try {

    const userId = req.user._id;
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        message: "Message required"
      });
    }

    const reply = await askAI(userId, message);

    res.json({
      success: true,
      reply
    });

  } catch (err) {

    console.error("AI error:", err);

    res.status(500).json({
      success: false,
      message: "AI failed"
    });

  }

});

export default router;