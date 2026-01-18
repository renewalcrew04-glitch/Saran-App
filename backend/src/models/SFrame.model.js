import mongoose from 'mongoose';

const sframeSchema = new mongoose.Schema(
  {
    uid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    mediaType: {
      type: String,
      enum: ['photo', 'video', 'text'],
      required: true
    },
    mediaUrl: {
      type: String,
      default: null
    },
    textContent: {
      type: String,
      maxlength: 500,
      default: null
    },
    mood: {
      type: String,
      default: 'neutral'
    },
    expiresAt: {
      type: Date,
      required: true,
      index: true // Index for cleanup queries
    },
    views: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }],
    echoes: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }],
    viewsCount: {
      type: Number,
      default: 0
    },
    echoesCount: {
      type: Number,
      default: 0
    }
  },
  {
    timestamps: true
  }
);

// TTL index to auto-delete expired SFrames
sframeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Index for fetching active SFrames
sframeSchema.index({ expiresAt: 1, createdAt: -1 });

const SFrame = mongoose.model('SFrame', sframeSchema);

export default SFrame;
