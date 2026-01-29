import Event from "../models/Event.model.js";
import { createNotification } from "../services/notification.service.js";

/**
 * CREATE EVENT
 * POST /api/events
 */
export const createEvent = async (req, res, next) => {
  try {
    // Placeholder – backend logic can be added later
    return res.json({ success: true, message: "Create event" });
  } catch (err) {
    next(err);
  }
};

/**
 * GET SINGLE EVENT
 * GET /api/events/:id
 */
export const getEvent = async (req, res, next) => {
  try {
    return res.json({ success: true, message: "Get event" });
  } catch (err) {
    next(err);
  }
};

/**
 * UPDATE EVENT
 * PUT /api/events/:id
 */
export const updateEvent = async (req, res, next) => {
  try {
    return res.json({ success: true, message: "Update event" });
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE EVENT
 * DELETE /api/events/:id
 */
export const deleteEvent = async (req, res, next) => {
  try {
    return res.json({ success: true, message: "Delete event" });
  } catch (err) {
    next(err);
  }
};

/**
 * GET ALL EVENTS
 * GET /api/events
 */
export const getEvents = async (req, res, next) => {
  try {
    return res.json({ success: true, message: "Get events" });
  } catch (err) {
    next(err);
  }
};

/**
 * ATTEND EVENT
 * POST /api/events/:id/attend
 */
export const attendEvent = async (req, res, next) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({
        success: false,
        message: "Event not found",
      });
    }

    const userId = req.user._id;

    if (event.attendees?.includes(userId)) {
      return res.status(400).json({
        success: false,
        message: "Already joined",
      });
    }

    event.attendees.push(userId);
    event.attendeesCount = (event.attendeesCount || 0) + 1;
    await event.save();

    // 🔔 Notify event owner
    if (event.uid.toString() !== userId.toString()) {
      await createNotification({
        userId: event.uid,
        actorId: userId,
        type: "space_join",
        entityId: event._id,
        entityType: "event",
      });
    }

    return res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

/**
 * UNATTEND EVENT
 * DELETE /api/events/:id/attend
 */
export const unattendEvent = async (req, res, next) => {
  try {
    return res.json({ success: true, message: "Unattend event" });
  } catch (err) {
    next(err);
  }
};
