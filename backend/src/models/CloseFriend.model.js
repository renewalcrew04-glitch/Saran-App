import mongoose from "mongoose";

const closeFriendSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    friend: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
  },
  { timestamps: true }
);

closeFriendSchema.index({ owner: 1, friend: 1 }, { unique: true });

const CloseFriend = mongoose.model("CloseFriend", closeFriendSchema);
export default CloseFriend;
