import mongoose from "mongoose";

const eventReminderSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    eventId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Event",
      required: true,
      index: true,
    },
    enabled: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

eventReminderSchema.index({ userId: 1, eventId: 1 }, { unique: true });

export default mongoose.model("EventReminder", eventReminderSchema);
