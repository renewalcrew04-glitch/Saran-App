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
 * Same logic as space update – uses Event model and hostUid.
 */
export const updateEvent = async (req, res, next) => {
  try {
    const { id } = req.params;
    const event = await Event.findById(id);
    if (!event) {
      return res.status(404).json({ message: "Event not found" });
    }
    const hostId = event.hostUid?.toString?.() ?? event.hostUid;
    const userId = req.user?._id?.toString?.() ?? req.user?._id;
    if (hostId !== userId) {
      return res.status(403).json({ message: "Only the host can update this event" });
    }
    const allowed = [
      "title", "description", "instructions", "startDate", "endDate",
      "location", "category", "price", "capacity", "isPublic",
      "coverUrl", "videoUrl", "faqs"
    ];
    const updates = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }
    if (updates.price !== undefined) updates.price = Number(updates.price);
    if (updates.capacity !== undefined) updates.capacity = Number(updates.capacity);
    if (updates.startDate) updates.startDate = new Date(updates.startDate);
    if (updates.endDate) updates.endDate = new Date(updates.endDate);
    const updated = await Event.findByIdAndUpdate(id, updates, { new: true, runValidators: true });
    return res.json(updated);
  } catch (err) {
    console.error("Update Event Error:", err);
    res.status(400).json({ message: err.message || "Failed to update event" });
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
