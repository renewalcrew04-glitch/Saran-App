import mongoose from "mongoose";

const episodeSchema = new mongoose.Schema(
  {
    podcastId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Podcast",
      required: true,
    },

    title: {
      type: String,
      required: true,
    },

    description: {
      type: String,
      default: "",
    },

    audioUrl: {
      type: String,
      required: true,
    },

    coverUrl: {
      type: String,
      default: "",
    },

    duration: {
      type: Number,
      default: 0,
    },

    listens: {
      type: Number,
      default: 0,
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
  },
  { timestamps: true }
);

export default mongoose.model("PodcastEpisode", episodeSchema);