import mongoose from "mongoose";

const muteSchema = new mongoose.Schema(
  {
    muter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    muted: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
  },
  { timestamps: true }
);

muteSchema.index({ muter: 1, muted: 1 }, { unique: true });

const Mute = mongoose.model("Mute", muteSchema);
export default Mute;
