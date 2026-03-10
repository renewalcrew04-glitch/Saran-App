import mongoose from "mongoose";

const messageSchema = new mongoose.Schema({
  role: String,
  content: String
});

const AIConversationSchema = new mongoose.Schema({

  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },

  messages: [messageSchema],

  memorySummary: {
    type: String,
    default: ""
  },

  longTermMemory: {
    name: String,
    college: String,
    location: String,
    lifeSituation: String,

    preferredLanguage: String,
    conversationStyle: String,

    interests: { type: [String], default: [] },
    importantTopics: { type: [String], default: [] },

    personalityTraits: { type: [String], default: [] },
    motivations: { type: [String], default: [] },
    currentChallenges: { type: [String], default: [] },
    growthAreas: { type: [String], default: [] },
    episodicMemories: { type: [String], default: [] },
    emotionalPatterns: { type: [String], default: [] },
    slangVocabulary: { type: [String], default: [] },
  },

  conversationMood: {
    type: String,
    default: "neutral"
  },

  moodTimeline: [
    {
      mood: String,
      date: Date
    }
  ],

  emotion: {
    type: String,
    default: "neutral"
  }

}, { timestamps: true });

export default mongoose.model("AIConversation", AIConversationSchema);
