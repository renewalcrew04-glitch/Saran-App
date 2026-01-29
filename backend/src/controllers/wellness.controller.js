import User from '../models/User.model.js';

// @desc    Get current wellness streak and stats
// @route   GET /api/wellness/streak
// @access  Private
export const getWellnessStreak = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({
      success: true,
      streak: user.wellnessStreak || 0,
      lastActivity: user.lastWellnessActivity
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update wellness activity (increment streak)
// @route   POST /api/wellness/activity
// @access  Private
export const updateWellnessActivity = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    const today = new Date();
    
    // Check if activity already logged today to prevent double counting
    let alreadyLoggedToday = false;
    if (user.lastWellnessActivity) {
      const last = new Date(user.lastWellnessActivity);
      if (last.toDateString() === today.toDateString()) {
        alreadyLoggedToday = true;
      }
    }

    if (!alreadyLoggedToday) {
      user.wellnessStreak = (user.wellnessStreak || 0) + 1;
      user.lastWellnessActivity = today;
      await user.save();
    }

    res.json({
      success: true,
      streak: user.wellnessStreak,
      message: alreadyLoggedToday ? 'Streak already updated today' : 'Streak incremented!'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get detailed wellness stats
// @route   GET /api/wellness/stats
// @access  Private
export const getWellnessStats = async (req, res, next) => {
  try {
    // For now, return basic user stats
    const user = await User.findById(req.user._id);
    
    res.json({
      success: true,
      stats: {
        currentStreak: user.wellnessStreak || 0,
        totalSessions: user.wellnessStreak || 0, // Simplified for now
        lastSession: user.lastWellnessActivity
      }
    });
  } catch (error) {
    next(error);
  }
};