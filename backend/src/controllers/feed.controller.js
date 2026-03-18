import mongoose from 'mongoose';
import Block from '../models/Block.model.js';
import Follow from '../models/Follow.model.js';
import Like from '../models/Like.model.js';
import Post from '../models/Post.model.js';
import User from '../models/User.model.js';

/** Get user IDs (ObjectIds) that viewer cannot see (viewer blocked them or they blocked viewer). */
async function getBlockedUserIdsForViewer(viewerId) {
  const asBlocker = await Block.find({ blocker: viewerId }).select('blocked').lean();
  const asBlocked = await Block.find({ blocked: viewerId }).select('blocker').lean();
  const ids = [
    ...asBlocker.map((b) => b.blocked.toString()),
    ...asBlocked.map((b) => b.blocker.toString()),
  ];
  const unique = [...new Set(ids)];
  return unique.map((id) => (mongoose.Types.ObjectId.isValid(id) ? new mongoose.Types.ObjectId(id) : id));
}

// @desc    Get home feed (posts from users you follow)
// @route   GET /api/feed/home
// @access  Private
export const getHomeFeed = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const { category, followingOnly } = req.query;

    const blockedIds = await getBlockedUserIdsForViewer(userId);
    const query = {
      isDeleted: false,
      visibility: 'public',
      ...(blockedIds.length > 0 ? { uid: { $nin: blockedIds } } : {}),
    };

    // CATEGORY FILTER
    if (category && category !== 'For You') {
      query.category = category;
    }

    // FOLLOWING FEED ONLY
    if (followingOnly === 'true') {
      const following = await Follow.find({
        follower: userId,
        status: 'accepted',
      }).select('following');

      const followingIds = following.map(f => f.following);
      followingIds.push(userId); // include own posts

      query.uid = { $in: followingIds };
    }

    const posts = await Post.find(query)
      .populate('uid', 'uid username name avatar verified')
      .populate('originalPostId', 'uid username type text media createdAt repostsCount')
      .populate('repostedByUid', 'uid username name avatar')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Likes info
    const postIds = posts.map(p => p._id);
    const likes = await Like.find({
      uid: userId,
      post: { $in: postIds },
    });

    const likedPostIds = new Set(likes.map(l => l.post.toString()));

    const postsWithLikes = posts.map(post => ({
      ...post.toObject(),
      isLiked: likedPostIds.has(post._id.toString()),
    }));

    const total = await Post.countDocuments(query);

    res.json({
      success: true,
      posts: postsWithLikes,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's feed (their posts)
// @route   GET /api/feed/user/:uid
// @access  Private
export const getUserFeed = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const userId = req.user._id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Find user
    const user = await User.findOne({ uid });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Block: if either has blocked the other, cannot view feed
    const blockRelation = await Block.findOne({
      $or: [
        { blocker: userId, blocked: user._id },
        { blocker: user._id, blocked: userId },
      ],
    });
    if (blockRelation) {
      return res.status(403).json({
        success: false,
        message: 'Cannot view this profile',
      });
    }

    // Check if viewing own feed or if user is public
    const isOwnFeed = user._id.toString() === userId.toString();
    const canView = isOwnFeed || !user.isPrivate;

    if (!canView) {
      // Check if current user follows this user
      const follow = await Follow.findOne({
        follower: userId,
        following: user._id,
        status: 'accepted'
      });

      if (!follow) {
        return res.status(403).json({
          success: false,
          message: 'Cannot view private profile'
        });
      }
    }

    // Get user's posts
    const posts = await Post.find({
      uid: user._id,
      isDeleted: false
    })
      .populate('uid', 'uid username name avatar verified')
      .populate('originalPostId', 'uid username type text media createdAt repostsCount')
      .populate('repostedByUid', 'uid username name avatar')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Get which posts current user has liked
    const postIds = posts.map(p => p._id);
    const likes = await Like.find({
      uid: userId,
      post: { $in: postIds }
    });
    const likedPostIds = new Set(likes.map(l => l.post.toString()));

    // Add isLiked flag
    const postsWithLikes = posts.map(post => ({
      ...post.toObject(),
      isLiked: likedPostIds.has(post._id.toString())
    }));

    // Get total count
    const total = await Post.countDocuments({
      uid: user._id,
      isDeleted: false
    });

    res.json({
      success: true,
      posts: postsWithLikes,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get explore feed (discover/public posts)
// @route   GET /api/feed/explore
// @access  Private
export const getExploreFeed = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const { type } = req.query; // Optional filter: text, photo, video

    const blockedIds = await getBlockedUserIdsForViewer(userId);
    const query = {
      isDeleted: false,
      visibility: 'public',
      type: { $in: ['text', 'photo', 'video'] },
      ...(blockedIds.length > 0 ? { uid: { $nin: blockedIds } } : {}),
    };

    if (type && ['text', 'photo', 'video'].includes(type)) {
      query.type = type;
    }

    // Get posts (sorted by engagement: likes + comments + reposts)
    const posts = await Post.find(query)
      .populate('uid', 'uid username name avatar verified')
      .populate('originalPostId', 'uid username type text media createdAt repostsCount')
      .sort({ 
        // Sort by engagement score (likes + comments + reposts)
        // Then by recency
        createdAt: -1 
      })
      .skip(skip)
      .limit(limit);

    // Get which posts current user has liked
    const postIds = posts.map(p => p._id);
    const likes = await Like.find({
      uid: userId,
      post: { $in: postIds }
    });
    const likedPostIds = new Set(likes.map(l => l.post.toString()));

    // Add isLiked flag
    const postsWithLikes = posts.map(post => ({
      ...post.toObject(),
      isLiked: likedPostIds.has(post._id.toString())
    }));

    // Get total count
    const total = await Post.countDocuments(query);

    res.json({
      success: true,
      posts: postsWithLikes,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    next(error);
  }
};
