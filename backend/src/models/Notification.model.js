import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    fromUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    fromUserName: {
      type: String,
      required: true // Denormalized
    },
    fromUserAvatar: {
      type: String,
      default: null
    },
    type: {
      type: String,
      enum: ['like', 'comment', 'reply', 'mention', 'tag', 'share', 'save', 'follow', 'dm'],
      required: true
    },
    entityId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null
    },
    entityType: {
      type: String,
      enum: ['post', 'comment', 'sframe', 'conversation'],
      default: null
    },
    read: {
      type: Boolean,
      default: false,
      index: true
    }
  },
  {
    timestamps: true
  }
);

// Indexes
notificationSchema.index({ userId: 1, read: 1, createdAt: -1 });
notificationSchema.index({ createdAt: -1 });

const Notification = mongoose.model('Notification', notificationSchema);

export default Notification;
