import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      index: true,
      required: true,
    },

    actorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    type: {
      type: String,
      enum: [
        "like",
        "comment",
        "reply",
        "mention",
        "repost",
        "quote",
        "follow",
        "follow_accept",
        "follow_request",

        "space_new",
        "space_join",
        "space_reminder",

        "sos_close",
        "sos_nearby",
        "sos_accept",
        "sos_resolve",

        "moderation",
        "verification",

        "wellness",
        "sdaily",

        "sframe_view",

        "dm",
      ],
      required: true,
    },

    entityId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },

    entityType: {
      type: String,
      enum: ["post", "comment", "event", "sos", "user", "conversation"],
      default: null,
    },

    meta: {
      type: Object,
      default: {},
    },

    read: {
      type: Boolean,
      default: false,
      index: true,
    },

    deleted: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

notificationSchema.index({ userId: 1, createdAt: -1 });

export default mongoose.model("Notification", notificationSchema);
