import mongoose from "mongoose";

const MindJournalSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },

    presentFeel: { type: String, default: "" },
    stopComparison: { type: String, default: "" },
    selfCare: { type: String, default: "" },
  },
  { timestamps: true }
);

export default mongoose.model("MindJournal", MindJournalSchema);
