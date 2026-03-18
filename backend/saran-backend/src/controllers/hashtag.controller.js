import Post from "../models/Post.model.js";

// Trending hashtags
export const getTrendingHashtags = async (req, res, next) => {
  try {
    const result = await Post.aggregate([
      { $match: { isDeleted: false, visibility: "public" } },
      { $unwind: "$hashtags" },
      {
        $group: {
          _id: "$hashtags",
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
      { $limit: 20 },
    ]);

    res.json({
      success: true,
      hashtags: result.map((h) => ({
        tag: h._id,
        count: h.count,
      })),
    });
  } catch (err) {
    next(err);
  }
};

// Posts by hashtag
export const getPostsByHashtag = async (req, res, next) => {
  try {
    const { tag } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const skip = (page - 1) * limit;

    const posts = await Post.find({
      hashtags: tag,
      isDeleted: false,
      visibility: "public",
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate("uid", "name username avatar verified");

    res.json({
      success: true,
      posts,
    });
  } catch (err) {
    next(err);
  }
};
