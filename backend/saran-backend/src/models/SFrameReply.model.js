import mongoose from "mongoose";

const sFrameReplySchema = new mongoose.Schema(
  {
    frameId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "SFrame",
      required: true,
      index: true,
    },

    fromUid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    toUid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    text: {
      type: String,
      required: true,
      maxlength: 300,
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  { versionKey: false }
);

export default mongoose.model("SFrameReply", sFrameReplySchema);
