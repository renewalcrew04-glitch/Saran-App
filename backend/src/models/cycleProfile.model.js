import mongoose from "mongoose";

const cycleProfileSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },

    lastPeriodDate: { type: Date, default: null },

    cycleLength: { type: Number, default: 28 }, // days
    periodLength: { type: Number, default: 5 }, // days
  },
  { timestamps: true }
);

export default mongoose.model("CycleProfile", cycleProfileSchema);
