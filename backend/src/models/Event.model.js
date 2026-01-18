import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema(
  {
    uid: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    title: {
      type: String,
      required: true,
      maxlength: 200
    },
    description: {
      type: String,
      maxlength: 2000
    },
    startDate: {
      type: Date,
      required: true
    },
    endDate: {
      type: Date,
      required: true
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: [Number], // [longitude, latitude]
      address: String
    },
    category: {
      type: String,
      default: null
    },
    attendees: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }],
    attendeesCount: {
      type: Number,
      default: 0
    },
    isPublic: {
      type: Boolean,
      default: true
    },
    imageUrl: {
      type: String,
      default: null
    }
  },
  {
    timestamps: true
  }
);

// Geospatial index for location-based queries
eventSchema.index({ location: '2dsphere' });
eventSchema.index({ startDate: 1 });
eventSchema.index({ uid: 1, createdAt: -1 });

const Event = mongoose.model('Event', eventSchema);

export default Event;
