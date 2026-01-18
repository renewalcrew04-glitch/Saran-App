import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema(
  {
    senderUid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    receiverUid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      required: true,
      index: true
    },
    text: {
      type: String,
      maxlength: 10000,
      default: null
    },
    imageUrl: {
      type: String,
      default: null
    },
    voiceUrl: {
      type: String,
      default: null
    },
    type: {
      type: String,
      enum: ['text', 'image', 'voice'],
      default: 'text'
    },
    read: {
      type: Boolean,
      default: false
    },
    reactions: {
      type: Map,
      of: String, // Reaction emoji
      default: new Map()
    }
  },
  {
    timestamps: true
  }
);

// Indexes
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ senderUid: 1, receiverUid: 1 });

const Message = mongoose.model('Message', messageSchema);

export default Message;
