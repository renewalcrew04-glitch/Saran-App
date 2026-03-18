import express from "express";
import { protect } from "../middleware/auth.middleware.js";
import AICompanionProfile from "../models/AICompanionProfile.model.js";

const router = express.Router();

router.post("/save", protect, async (req, res) => {

  const userId = req.user._id;

  const data = req.body;

  let profile = await AICompanionProfile.findOne({ userId });

  if (profile) {
    profile = await AICompanionProfile.findOneAndUpdate(
      { userId },
      data,
      { new: true }
    );
  } else {
    profile = await AICompanionProfile.create({
      userId,
      ...data
    });
  }

  res.json({
    success: true,
    profile
  });

});

export default router;
