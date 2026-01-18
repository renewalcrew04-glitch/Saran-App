// Placeholder controllers
export const getWellnessStreak = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Get wellness streak' });
  } catch (error) {
    next(error);
  }
};

export const updateWellnessActivity = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Update wellness activity' });
  } catch (error) {
    next(error);
  }
};

export const getWellnessStats = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Get wellness stats' });
  } catch (error) {
    next(error);
  }
};
