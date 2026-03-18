import mongoose from "mongoose";

const bookingSchema = new mongoose.Schema(
  {
    eventId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Event",
      required: true,
    },
    uid: { type: String, required: true },
    slots: { type: Number, default: 1 },
  },
  { timestamps: true }
);

bookingSchema.index({ eventId: 1, uid: 1 }, { unique: true });

export default mongoose.model("EventBooking", bookingSchema);
