import mongoose from 'mongoose';

const postSchema = new mongoose.Schema(
  {
    uid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    username: {
      type: String,
      required: true // Denormalized for quick access
    },
    hideLikeCount: {
      type: Boolean,
      default: false,
    },
    edited: {
      type: Boolean,
      default: false,
    },
    type: {
      type: String,
      enum: ['text', 'photo', 'video', 'repost', 'quote'],
      required: true
    },
    text: {
      type: String,
      maxlength: 10000,
      default: ''
    },
    media: [{
      type: String, // S3 URLs
      default: []
    }],
    thumbnail: {
      type: String,
      default: null
    },
    isQuote: {
      type: Boolean,
      default: false
    },
    originalPostId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
      default: null
    },
    // Repost info
    repostedByUid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    },
    repostedByName: {
      type: String,
      default: null
    },
    // Counts
    likesCount: {
      type: Number,
      default: 0
    },
    commentsCount: {
      type: Number,
      default: 0
    },
    repostsCount: {
      type: Number,
      default: 0
    },
    sharesCount: {
      type: Number,
      default: 0
    },
    // Metadata
    visibility: {
      type: String,
      enum: ['public', 'private'],
      default: 'public'
    },
    isDeleted: {
      type: Boolean,
      default: false
    },
    category: {
      type: String,
      default: null
    },
    hashtags: [{
      type: String
    }],
    mentions: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }]
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
  }
);

// Indexes
postSchema.index({ uid: 1, createdAt: -1 });
postSchema.index({ type: 1, createdAt: -1 });
postSchema.index({ visibility: 1, createdAt: -1 });
postSchema.index({ createdAt: -1 });
postSchema.index({ text: 'text' }); // Text search

// Virtual for likes
postSchema.virtual('likes', {
  ref: 'Like',
  localField: '_id',
  foreignField: 'post'
});

// Virtual for comments
postSchema.virtual('comments', {
  ref: 'Comment',
  localField: '_id',
  foreignField: 'post'
});

const Post = mongoose.model('Post', postSchema);

export default Post;
