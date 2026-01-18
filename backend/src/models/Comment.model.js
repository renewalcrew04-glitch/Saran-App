import mongoose from 'mongoose';

const commentSchema = new mongoose.Schema(
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
    },
    parentComment: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Comment',
      default: null // For nested replies
    },
    text: {
      type: String,
      required: true,
      maxlength: 2000
    },
    mentions: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }],
    likesCount: {
      type: Number,
      default: 0
    },
    repliesCount: {
      type: Number,
      default: 0
    },
    isDeleted: {
      type: Boolean,
      default: false
    }
  },
  {
    timestamps: true
  }
);

// Indexes
commentSchema.index({ post: 1, createdAt: -1 });
commentSchema.index({ parentComment: 1, createdAt: -1 });

const Comment = mongoose.model('Comment', commentSchema);

export default Comment;
