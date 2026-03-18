import mongoose from "mongoose";

const saveSchema = new mongoose.Schema(
  {
    uid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    post: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Post",
      required: true,
      index: true,
    },
  },
  { timestamps: true }
);

saveSchema.index({ uid: 1, post: 1 }, { unique: true });

const Save = mongoose.model("Save", saveSchema);

export default Save;
