import mongoose from "mongoose";

const contentMuteSchema = new mongoose.Schema(
  {
    uid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    mutedWords: [
      {
        type: String,
        lowercase: true,
        trim: true,
      },
    ],
    mutedHashtags: [
      {
        type: String,
        lowercase: true,
        trim: true,
      },
    ],
  },
  { timestamps: true }
);

const ContentMute = mongoose.model(
  "ContentMute",
  contentMuteSchema
);

export default ContentMute;
