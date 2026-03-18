import mongoose from "mongoose";

const aiProfileSchema = new mongoose.Schema({

  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    unique: true
  },

  interests: [String],

  personality: String,

  moodPattern: String,

  preferences: [String],

  summary: String

}, { timestamps: true });

export default mongoose.model("AIProfile", aiProfileSchema);