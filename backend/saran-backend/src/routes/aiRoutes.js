import express from "express";
import { protect } from "../middleware/auth.middleware.js";
import { askAI } from "../services/aiService.js";

const router = express.Router();

const userCooldown = new Map();

router.post("/chat", protect, async (req, res) => {

  try {

    const userId = req.user._id.toString();
    const { message, language } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        message: "Message required"
      });
    }

    const now = Date.now();
    const last = userCooldown.get(userId) || 0;

    if (now - last < 300) {
      return res.json({
        success: true,
        reply: "..."
      });
    }

    userCooldown.set(userId, now);

    const reply = await askAI(userId, message, language);

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