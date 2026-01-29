import Follow from '../models/Follow.model.js';
import Post from '../models/Post.model.js';
import User from '../models/User.model.js';

// @desc    Get user profile by UID
// @route   GET /api/users/:uid
// @access  Private
export const getUserProfile = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const currentUserId = req.user._id;

    // Find user by UID
    const user = await User.findOne({ uid }).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if current user is following this user
    let isFollowing = false;
    if (currentUserId.toString() !== user._id.toString()) {
      const follow = await Follow.findOne({
        follower: currentUserId,
        following: user._id,
        status: 'accepted'
      });
      isFollowing = !!follow;
    }

    // Check if this user is following current user
    let isFollowedBy = false;
    if (currentUserId.toString() !== user._id.toString()) {
      const follow = await Follow.findOne({
        follower: user._id,
        following: currentUserId,
        status: 'accepted'
      });
      isFollowedBy = !!follow;
    }

    const postsCount = await Post.countDocuments({
  uid: user._id,
  isDeleted: false,
});

    const userObj = user.toObject();

res.json({
  success: true,
  user: {
    ...userObj,
    postsCount,     // ✅ injected, not mutated
    isFollowing,
    isFollowedBy,
  }
});
  } catch (error) {
    next(error);
  }
};

// @desc    Update user profile
// @route   PUT /api/users/:uid
// @access  Private (own profile only)
export const updateUserProfile = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const currentUserId = req.user._id;
    const { name, bio, avatar, isPrivate } = req.body;

    // Find user
    const user = await User.findOne({ uid });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if user is updating their own profile
    if (user._id.toString() !== currentUserId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this profile'
      });
    }

    // Update fields
    if (name) user.name = name;
    if (bio !== undefined) user.bio = bio;
    if (avatar !== undefined) user.avatar = avatar;
    if (isPrivate !== undefined) user.isPrivate = isPrivate;

    // Mark profile as completed if not already
    if (!user.profileCompleted && name && bio) {
      user.profileCompleted = true;
    }

    const updatedUser = await user.save();

    res.json({
      success: true,
      user: {
        uid: updatedUser.uid,
        username: updatedUser.username,
        email: updatedUser.email,
        name: updatedUser.name,
        avatar: updatedUser.avatar,
        bio: updatedUser.bio,
        isPrivate: updatedUser.isPrivate,
        profileCompleted: updatedUser.profileCompleted,
        verified: updatedUser.verified,
        followersCount: updatedUser.followersCount,
        followingCount: updatedUser.followingCount,
        postsCount: updatedUser.postsCount,
        createdAt: updatedUser.createdAt,
        updatedAt: updatedUser.updatedAt,
        wellnessPoints: updatedUser.wellnessPoints,
        wellnessStreak: updatedUser.wellnessStreak
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Follow a user
// @route   POST /api/users/:uid/follow
// @access  Private
export const followUser = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const currentUserId = req.user._id;

    // Find target user
    const targetUser = await User.findOne({ uid });

    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if trying to follow self
    if (targetUser._id.toString() === currentUserId.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot follow yourself'
      });
    }

    // Check if already following
    const existingFollow = await Follow.findOne({
      follower: currentUserId,
      following: targetUser._id
    });

    if (existingFollow) {
      if (existingFollow.status === 'accepted') {
        return res.status(400).json({
          success: false,
          message: 'Already following this user'
        });
      } else if (existingFollow.status === 'pending') {
        return res.status(400).json({
          success: false,
          message: 'Follow request already pending'
        });
      }
    }

    // Create follow relationship
    const followStatus = targetUser.isPrivate ? 'pending' : 'accepted';
    
    const follow = await Follow.create({
      follower: currentUserId,
      following: targetUser._id,
      status: followStatus
    });

    // Update follower counts
    if (followStatus === 'accepted') {
      await User.findByIdAndUpdate(targetUser._id, {
        $inc: { followersCount: 1 }
      });
      await User.findByIdAndUpdate(currentUserId, {
        $inc: { followingCount: 1 }
      });
    }

    res.json({
      success: true,
      message: followStatus === 'pending' 
        ? 'Follow request sent' 
        : 'Successfully followed user',
      follow: {
        id: follow._id,
        status: follow.status
      }
    });
  } catch (error) {
    // Handle duplicate follow error
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Already following this user'
      });
    }
    next(error);
  }
};

// @desc    Unfollow a user
// @route   DELETE /api/users/:uid/follow
// @access  Private
export const unfollowUser = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const currentUserId = req.user._id;

    // Find target user
    const targetUser = await User.findOne({ uid });

    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Find and delete follow relationship
    const follow = await Follow.findOneAndDelete({
      follower: currentUserId,
      following: targetUser._id
    });

    if (!follow) {
      return res.status(400).json({
        success: false,
        message: 'Not following this user'
      });
    }

    // Update follower counts (only if was accepted)
    if (follow.status === 'accepted') {
      await User.findByIdAndUpdate(targetUser._id, {
        $inc: { followersCount: -1 }
      });
      await User.findByIdAndUpdate(currentUserId, {
        $inc: { followingCount: -1 }
      });
    }

    res.json({
      success: true,
      message: 'Successfully unfollowed user'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's followers
// @route   GET /api/users/:uid/followers
// @access  Private
export const getFollowers = async (req, res, next) => {
  try {
    const { uid } = req.params;
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

    // Get followers
    const follows = await Follow.find({
      following: user._id,
      status: 'accepted'
    })
      .populate('follower', 'uid username name avatar verified')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const followers = follows.map(follow => ({
      ...follow.follower.toObject(),
      followedAt: follow.createdAt
    }));

    // Get total count
    const total = await Follow.countDocuments({
      following: user._id,
      status: 'accepted'
    });

    res.json({
      success: true,
      followers,
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

// @desc    Get users that a user is following
// @route   GET /api/users/:uid/following
// @access  Private
export const getFollowing = async (req, res, next) => {
  try {
    const { uid } = req.params;
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

    // Get following
    const follows = await Follow.find({
      follower: user._id,
      status: 'accepted'
    })
      .populate('following', 'uid username name avatar verified')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const following = follows.map(follow => ({
      ...follow.following.toObject(),
      followedAt: follow.createdAt
    }));

    // Get total count
    const total = await Follow.countDocuments({
      follower: user._id,
      status: 'accepted'
    });

    res.json({
      success: true,
      following,
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

export const deleteMyAccount = async (req, res, next) => {
  try {
    const currentUserId = req.user._id;

    await User.deleteOne({ _id: currentUserId });

    return res.json({ success: true, message: "Account deleted" });
  } catch (err) {
    next(err);
  }
};

// @desc    Search users
// @route   GET /api/users/search?q=query
// @access  Private
export const searchUsers = async (req, res, next) => {
  try {
    const { q } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    // Search users by username or name
    const searchRegex = new RegExp(q.trim(), 'i');
    
    const users = await User.find({
      $or: [
        { username: searchRegex },
        { name: searchRegex }
      ]
    })
      .select('uid username name avatar bio verified followersCount followingCount postsCount')
      .sort({ followersCount: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Get total count
    const total = await User.countDocuments({
      $or: [
        { username: searchRegex },
        { name: searchRegex }
      ]
    });

    res.json({
      success: true,
      users,
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
// @desc    Get posts of a user
// @route   GET /api/users/:uid/posts
// @access  Private
export const getUserPosts = async (req, res, next) => {
  try {
    const { uid } = req.params;

    // Find user by UID (string)
    const user = await User.findOne({ uid });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const posts = await Post.find({
      uid: user._id,          // ✅ CORRECT FIELD
      isDeleted: false,
    })
      .sort({ createdAt: -1 });

    return res.json({
      success: true,
      posts,
    });
  } catch (error) {
    next(error);
  }
};
