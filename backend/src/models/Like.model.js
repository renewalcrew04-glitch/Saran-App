import mongoose from 'mongoose';

const likeSchema = new mongoose.Schema(
  {
    uid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    post: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
      required: true,
      index: true
    }
  },
  {
    timestamps: true
  }
);

// Unique compound index to prevent duplicate likes
likeSchema.index({ uid: 1, post: 1 }, { unique: true });

const Like = mongoose.model('Like', likeSchema);

export default Like;
