import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema(
  {
    hostUid: {
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
    instructions: {
      type: String,
      default: ""
    },
    startDate: {
      type: Date,
      required: true
    },
    endDate: {
      type: Date,
      required: true
    },
    // ✅ Location is a String (Matches your Frontend)
    location: {
      type: String, 
      required: true
    },
    category: {
      type: String,
      default: 'Social'
    },
    price: {
      type: Number,
      default: 0
    },
    capacity: {
      type: Number,
      default: 50
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
    coverUrl: { type: String, default: null },
    videoUrl: { type: String, default: null },
    faqs: [
      {
        question: { type: String, required: true },
        answer: { type: String, default: "" }
      }
    ]
  },
  { timestamps: true }
);

// Indexes
eventSchema.index({ startDate: 1 });
eventSchema.index({ hostUid: 1, createdAt: -1 });

const Event = mongoose.model('Event', eventSchema);

// ✅ CRITICAL FIX: This deletes the old conflicting 'location' index
Event.syncIndexes().then(() => {
  console.log("✅ Event Indexes Synced (Bad indexes dropped)");
}).catch(err => {
  console.log("Index Sync Error (Ignore if first run):", err.message);
});

export default Event;