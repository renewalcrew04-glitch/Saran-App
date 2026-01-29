import mongoose from "mongoose";

const scyclePeriodSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      index: true,
    },

    // last period start date
    lastPeriodStart: {
      type: Date,
      default: null,
    },

    // average cycle length (default 28)
    cycleLength: {
      type: Number,
      default: 28,
      min: 15,
      max: 60,
    },
  },
  { timestamps: true }
);

export default mongoose.model("SCyclePeriod", scyclePeriodSchema);
