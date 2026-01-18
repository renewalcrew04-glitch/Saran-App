import mongoose from 'mongoose';

const followSchema = new mongoose.Schema(
  {
    follower: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    following: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'blocked'],
      default: 'accepted'
    }
  },
  {
    timestamps: true
  }
);

// Unique compound index to prevent duplicate follows
followSchema.index({ follower: 1, following: 1 }, { unique: true });

// Prevent self-follow
followSchema.pre('save', function (next) {
  if (this.follower.toString() === this.following.toString()) {
    const error = new Error('Cannot follow yourself');
    next(error);
  } else {
    next();
  }
});

const Follow = mongoose.model('Follow', followSchema);

export default Follow;
