import Event from "../models/Event.model.js";
import EventBooking from "../models/EventBooking.js";
import mongoose from "mongoose";

/* ================= CREATE EVENT ================= */
export const createEvent = async (req, res) => {
  try {
    // 1. Prepare the data
    const eventData = {
      ...req.body,
      hostUid: req.user._id, // ✅ Critical Fix: Uses 'hostUid' to match Model
      // Ensure numeric fields are actually numbers
      price: Number(req.body.price || 0),
      capacity: Number(req.body.capacity || 50),
    };

    // 2. Create in DB
    const event = await Event.create(eventData);

    res.status(201).json(event);
  } catch (e) {
    console.error("Create Event Error:", e);
    // Return a clear error message
    res.status(400).json({ message: e.message || "Failed to create event" });
  }
};

/* ================= GET EVENTS (Feed) ================= */
export const getEvents = async (req, res) => {
  const { category, cursor, limit = 10 } = req.query;

  // 1. Build Match Query
  const matchStage = { isPublic: true }; 
  if (category && category !== "All") {
    matchStage.category = category;
  }
  
  // Pagination cursor logic
  if (cursor) {
    matchStage._id = { $lt: new mongoose.Types.ObjectId(cursor) };
  }

  try {
    // 2. Run Aggregation to get events + check if I joined
    const events = await Event.aggregate([
      { $match: matchStage },
      { $sort: { _id: -1 } },
      { $limit: Number(limit) + 1 }, // Fetch 1 extra to check if more exist

      // Lookup to see if current user has booked this event
      {
        $lookup: {
          from: "eventbookings",
          let: { eventId: "$_id" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$eventId", "$$eventId"] },
                    { $eq: ["$uid", req.user._id] }, // Check against MY user ID
                  ],
                },
              },
            },
          ],
          as: "myBooking",
        },
      },
      // Add 'joinedByMe' boolean field
      {
        $addFields: {
          joinedByMe: { $gt: [{ $size: "$myBooking" }, 0] },
        },
      },
      // Remove the temp lookup array to keep response clean
      { $project: { myBooking: 0 } },
    ]);

    // 3. Handle Pagination
    const hasNextPage = events.length > limit;
    const sliced = hasNextPage ? events.slice(0, limit) : events;

    res.json({
      items: sliced,
      nextCursor: hasNextPage && sliced.length > 0 ? sliced[sliced.length - 1]._id : null,
    });
  } catch (error) {
    console.error("Get Events Error:", error);
    res.status(500).json({ message: "Failed to fetch events" });
  }
};

/* ================= GET SINGLE EVENT ================= */
export const getEventById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find event
    const event = await Event.findById(id).lean();
    if (!event) {
      return res.status(404).json({ message: "Event not found" });
    }

    // Check if I joined
    const booking = await EventBooking.findOne({ 
      eventId: id, 
      uid: req.user._id 
    });

    // Return event with joined status
    res.json({
      ...event,
      joinedByMe: !!booking
    });
  } catch (error) {
    console.error("Get Single Event Error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

/* ================= JOIN EVENT ================= */
export const joinEvent = async (req, res) => {
  const { id } = req.params;
  const uid = req.user._id;

  try {
    const event = await Event.findById(id);
    if (!event) return res.status(404).json({ message: "Event not found" });

    // Check if already joined
    const exists = await EventBooking.findOne({ eventId: id, uid });
    if (exists) {
      return res.status(400).json({ message: "Already joined" });
    }

    // Create Booking
    await EventBooking.create({ eventId: id, uid });
    
    // Increment Count
    await Event.findByIdAndUpdate(id, { $inc: { attendeesCount: 1 } });

    res.json({ success: true });
  } catch (error) {
    console.error("Join Event Error:", error);
    res.status(500).json({ message: error.message });
  }
};

/* ================= GET HOSTED EVENTS (My Events Tab 1) ================= */
export const getHostedEvents = async (req, res) => {
  try {
    const uid = req.user._id;
    // Find events where I am the HOST
    const events = await Event.find({ hostUid: uid }).sort({ createdAt: -1 });
    res.json(events);
  } catch (error) {
    console.error("Get Hosted Events Error:", error);
    res.status(500).json({ message: error.message });
  }
};

/* ================= GET BOOKED EVENTS (My Events Tab 2) ================= */
export const getBookedEvents = async (req, res) => {
  try {
    const uid = req.user._id;
    // Find bookings for ME, populate the Event details
    const bookings = await EventBooking.find({ uid }).populate("eventId");
    
    // Filter out any where event was deleted (null)
    const events = bookings
      .filter(b => b.eventId != null)
      .map((b) => b.eventId); // Extract just the event data

    res.json(events);
  } catch (error) {
    console.error("Get Booked Events Error:", error);
    res.status(500).json({ message: error.message });
  }
};