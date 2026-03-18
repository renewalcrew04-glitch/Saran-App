import mongoose from "mongoose";

const cycleLogSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },

    date: { type: Date, required: true },

    mood: { type: String, default: "" }, // "happy", "calm", "sad", "tired", "angry", etc

    symptoms: { type: [String], default: [] },

    periodStarted: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// One log per day per user (prevents duplicates)
cycleLogSchema.index({ userId: 1, date: 1 }, { unique: true });

export default mongoose.model("CycleLog", cycleLogSchema);
