import mongoose from "mongoose";

const AIMemorySchema = new mongoose.Schema({

  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },

  text: String,

  embedding: [Number],

  createdAt: {
    type: Date,
    default: Date.now
  }

});

export default mongoose.model("AIMemory", AIMemorySchema);
