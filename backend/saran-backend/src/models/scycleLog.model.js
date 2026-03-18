import mongoose from "mongoose";

const scycleLogSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
      index: true,
    },

    // mood examples: "happy", "sad", "angry", "tired", "calm"
    mood: {
      type: String,
      required: true,
    },

    // symptoms examples: ["cramps", "headache", "bloating"]
    symptoms: {
      type: [String],
      default: [],
    },

    note: {
      type: String,
      default: "",
    },

    // true only when user clicks "Period Started"
    isPeriodStart: {
      type: Boolean,
      default: false,
    },

    // store dayKey so 1 log per day per user
    dayKey: {
      type: String,
      required: true,
      index: true,
    },
  },
  { timestamps: true }
);

// 1 log per day per user
scycleLogSchema.index({ userId: 1, dayKey: 1 }, { unique: true });

export default mongoose.model("SCycleLog", scycleLogSchema);
