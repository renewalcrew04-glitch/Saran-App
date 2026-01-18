import mongoose from 'mongoose';

const conversationSchema = new mongoose.Schema(
  {
    participants: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    }],
    lastMessage: {
      type: String,
      default: ''
    },
    lastMessageAt: {
      type: Date,
      default: Date.now
    },
    unread: {
      type: Map,
      of: Number,
      default: new Map()
    },
    archived: {
      type: Map,
      of: Boolean,
      default: new Map()
    },
    muted: {
      type: Map,
      of: Boolean,
      default: new Map()
    },
    pinned: {
      type: Map,
      of: Boolean,
      default: new Map()
    }
  },
  {
    timestamps: true
  }
);

// Index for finding conversations by participants
conversationSchema.index({ participants: 1 });

const Conversation = mongoose.model('Conversation', conversationSchema);

export default Conversation;
