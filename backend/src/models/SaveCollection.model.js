import mongoose from "mongoose";

const saveCollectionSchema = new mongoose.Schema(
  {
    uid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      maxlength: 50,
    },
    posts: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Post",
      },
    ],
  },
  { timestamps: true }
);

saveCollectionSchema.index({ uid: 1, name: 1 }, { unique: true });

const SaveCollection = mongoose.model(
  "SaveCollection",
  saveCollectionSchema
);

export default SaveCollection;
