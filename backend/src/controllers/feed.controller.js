// Placeholder controllers
export const getHomeFeed = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Get home feed' });
  } catch (error) {
    next(error);
  }
};

export const getUserFeed = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Get user feed' });
  } catch (error) {
    next(error);
  }
};

export const getExploreFeed = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Get explore feed' });
  } catch (error) {
    next(error);
  }
};
