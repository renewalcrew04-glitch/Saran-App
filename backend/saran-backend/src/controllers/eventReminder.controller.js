import EventReminder from "../models/EventReminder.model.js";

export const getReminderStatus = async (req, res, next) => {
  try {
    const reminder = await EventReminder.findOne({
      userId: req.user._id,
      eventId: req.params.eventId,
    });

    res.json({
      success: true,
      enabled: reminder ? reminder.enabled : true,
    });
  } catch (err) {
    next(err);
  }
};

export const updateReminderStatus = async (req, res, next) => {
  try {
    const { enabled } = req.body;

    const reminder = await EventReminder.findOneAndUpdate(
      {
        userId: req.user._id,
        eventId: req.params.eventId,
      },
      { enabled },
      { upsert: true, new: true }
    );

    res.json({
      success: true,
      enabled: reminder.enabled,
    });
  } catch (err) {
    next(err);
  }
};
