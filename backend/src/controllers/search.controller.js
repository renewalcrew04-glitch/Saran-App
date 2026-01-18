// Placeholder controllers
export const searchPosts = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Search posts' });
  } catch (error) {
    next(error);
  }
};

export const searchUsers = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Search users' });
  } catch (error) {
    next(error);
  }
};

export const searchAll = async (req, res, next) => {
  try {
    res.json({ success: true, message: 'Search all' });
  } catch (error) {
    next(error);
  }
};
