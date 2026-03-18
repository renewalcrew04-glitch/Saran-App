import mongoose from "mongoose";

const sFrameSchema = new mongoose.Schema(
  {
    uid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    mediaType: {
      type: String,
      enum: ["text", "photo", "video"],
      required: true,
    },

    mediaUrl: {
      type: String,
    },

    textContent: {
      type: String,
      maxlength: 200,
    },

    mood: {
      type: String,
      default: null,
    },

    views: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    /** User ids who sent a heart (echo) on this story. Shown to owner in "Who viewed" with heart. */
    echoes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    createdAt: {
      type: Date,
      default: Date.now,
      index: true,
    },

    expiresAt: {
      type: Date,
      index: true,
    },
  },
  { versionKey: false }
);

export default mongoose.model("SFrame", sFrameSchema);
