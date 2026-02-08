import mongoose from 'mongoose';

const sosSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    message: {
      type: String,
      trim: true,
      default: '',
    },

    sendToCloseFriends: {
      type: Boolean,
      default: false,
    },

    sendToNearby: {
      type: Boolean,
      default: false,
    },

    location: {
      type: {
        type: String,
        enum: ['Point'],
        // no default: only set when we have coordinates
      },
      coordinates: {
        type: [Number], // [lng, lat]
        index: '2dsphere',
      },
    },

    radiusKm: {
      type: Number,
      default: 2,
    },

    status: {
      type: String,
      enum: ['active', 'cancelled', 'resolved'],
      default: 'active',
      index: true,
    },

    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    resolvedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// 🔥 Required for geo queries
sosSchema.index({ location: '2dsphere' });

const SOS = mongoose.model('SOS', sosSchema);
export default SOS;
