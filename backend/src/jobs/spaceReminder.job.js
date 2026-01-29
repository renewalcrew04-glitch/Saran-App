import cron from "node-cron";
import Event from "../models/Event.model.js";
import EventReminder from "../models/EventReminder.model.js";
import { createNotification } from "../services/notification.service.js";

/**
 * Runs every 5 minutes
 * Sends reminder for events starting in next 15 minutes
 */
cron.schedule("*/5 * * * *", async () => {
  try {
    const now = new Date();
    const in15 = new Date(now.getTime() + 15 * 60 * 1000);

    const events = await Event.find({
      startDate: { $gte: now, $lte: in15 },
      isDeleted: { $ne: true },
    });

    for (const event of events) {
      for (const userId of event.attendees) {
        // 🔔 Check per-space reminder override
        const reminder = await EventReminder.findOne({
          userId,
          eventId: event._id,
        });

        // If explicitly disabled → skip
        if (reminder && reminder.enabled === false) continue;

        await createNotification({
          userId,
          type: "space_reminder",
          entityId: event._id,
          entityType: "event",
        });
      }
    }
  } catch (err) {
    console.error("SPACE REMINDER CRON ERROR:", err);
  }
});
