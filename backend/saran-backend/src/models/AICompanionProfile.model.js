import mongoose from "mongoose";

const AICompanionProfileSchema = new mongoose.Schema({

  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },

  occupationType: String,
  occupationDetail: String,

  maritalStatus: String,

  talkFrequency: String,

  emotionalNeeds: [String],

  personalStatement: String,

  createdAt: {
    type: Date,
    default: Date.now
  }

});

export default mongoose.model("AICompanionProfile", AICompanionProfileSchema);