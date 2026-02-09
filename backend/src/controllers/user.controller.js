import mongoose from 'mongoose';
import Block from '../models/Block.model.js';
import CloseFriend from '../models/CloseFriend.model.js';
import Follow from '../models/Follow.model.js';
import Mute from '../models/Mute.model.js';
import Post from '../models/Post.model.js';
import User from '../models/User.model.js';
import { createNotification } from '../services/notification.service.js';

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

    // Block: viewer cannot see profile if either has blocked the other
    const blocked = await Block.findOne({
      $or: [
        { blocker: currentUserId, blocked: user._id },
        { blocker: user._id, blocked: currentUserId },
      ],
    });
    if (blocked) {
      return res.status(403).json({
        success: false,
        message: 'Cannot view this profile',
      });
    }

    // Check if current user is following this user (accepted) or has pending request
    let isFollowing = false;
    let isFollowPending = false;
    if (currentUserId.toString() !== user._id.toString()) {
      const accepted = await Follow.findOne({
        follower: currentUserId,
        following: user._id,
        status: 'accepted'
      });
      isFollowing = !!accepted;
      if (!isFollowing) {
        const pending = await Follow.findOne({
          follower: currentUserId,
          following: user._id,
          status: 'pending'
        });
        isFollowPending = !!pending;
      }
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
    isFollowPending,
    isFollowedBy,
  }
});
  } catch (error) {
    next(error);
  }
};

// @desc    Update current user profile (PUT /api/users/me)
// @route   PUT /api/users/me
// @access  Private
export const updateMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    const { name, bio, avatar, coverImage, isPrivate } = req.body;
    if (name !== undefined) user.name = name;
    if (bio !== undefined) user.bio = bio;
    if (avatar !== undefined) user.avatar = avatar;
    if (coverImage !== undefined) user.coverImage = coverImage;
    if (isPrivate !== undefined) user.isPrivate = isPrivate;
    if (!user.profileCompleted && name && bio) user.profileCompleted = true;
    const updated = await user.save();
    const obj = updated.toObject();
    delete obj.password;
    res.json({ success: true, user: obj });
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
    const { name, bio, avatar, coverImage, isPrivate } = req.body;

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
    if (coverImage !== undefined) user.coverImage = coverImage;
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
        coverImage: updatedUser.coverImage,
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

    // Find target user by uid (string) or by _id if uid looks like ObjectId
    let targetUser = await User.findOne({ uid });
    if (!targetUser && mongoose.Types.ObjectId.isValid(uid)) {
      targetUser = await User.findById(uid);
    }
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
        return res.status(200).json({
          success: true,
          status: 'pending',
          message: 'Request sent',
          follow: {
            id: existingFollow._id,
            status: 'pending'
          }
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

    // Notify target user: "follow" when public, "follow_request" when private (pending)
    if (followStatus === 'pending') {
      await createNotification({
        userId: targetUser._id,
        actorId: currentUserId,
        type: 'follow_request',
        entityId: follow._id,
        entityType: 'user',
        meta: { followId: follow._id.toString() }
      });
    } else {
      await createNotification({
        userId: targetUser._id,
        actorId: currentUserId,
        type: 'follow',
        entityId: targetUser._id,
        entityType: 'user'
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

    // Find target user by uid or by _id (same as followUser)
    let targetUser = await User.findOne({ uid });
    if (!targetUser && mongoose.Types.ObjectId.isValid(uid)) {
      targetUser = await User.findById(uid);
    }
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
// For private accounts: only owner or accepted followers can see the list.
export const getFollowers = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 100, 200);
    const skip = (page - 1) * limit;

    // Find user by uid, or by _id if uid looks like a MongoDB ObjectId (so all users are findable)
    let user = await User.findOne({ uid });
    if (!user && mongoose.Types.ObjectId.isValid(uid)) {
      user = await User.findById(uid);
    }
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const viewerId = req.user._id;
    const isOwner = viewerId.toString() === user._id.toString();

    const blockRelation = await Block.findOne({
      $or: [
        { blocker: viewerId, blocked: user._id },
        { blocker: user._id, blocked: viewerId },
      ],
    });
    if (blockRelation) {
      return res.status(403).json({
        success: false,
        message: 'Cannot view this profile',
      });
    }

    if (user.isPrivate && !isOwner) {
      const accepted = await Follow.findOne({
        follower: viewerId,
        following: user._id,
        status: 'accepted',
      });
      if (!accepted) {
        return res.json({
          success: true,
          followers: [],
          restricted: true,
          pagination: { page: 1, limit, total: 0, pages: 0 },
        });
      }
    }

    const viewerBlockedIds = await Block.find({ $or: [{ blocker: viewerId }, { blocked: viewerId }] })
      .select('blocker blocked')
      .lean();
    const hideFromViewer = new Set();
    viewerBlockedIds.forEach((b) => {
      hideFromViewer.add(b.blocker.toString());
      hideFromViewer.add(b.blocked.toString());
    });
    hideFromViewer.delete(viewerId.toString());

    // Get followers
    const follows = await Follow.find({
      following: user._id,
      status: 'accepted'
    })
      .populate('follower', 'uid username name avatar verified')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const followerList = follows
      .filter((f) => f.follower && !hideFromViewer.has(f.follower._id.toString()))
      .map((f) => ({ user: f.follower.toObject(), followedAt: f.createdAt }));

    const followerIds = followerList.map((f) => f.user._id);
    const viewerFollowingAccepted = await Follow.find({
      follower: viewerId,
      following: { $in: followerIds },
      status: 'accepted'
    }).select('following').lean();
    const viewerFollowPending = await Follow.find({
      follower: viewerId,
      following: { $in: followerIds },
      status: 'pending'
    }).select('following').lean();
    const acceptedSet = new Set(viewerFollowingAccepted.map((f) => f.following.toString()));
    const pendingSet = new Set(viewerFollowPending.map((f) => f.following.toString()));

    const followers = followerList.map(({ user: u, followedAt }) => ({
      ...u,
      followedAt,
      isFollowing: acceptedSet.has(u._id.toString()),
      isFollowPending: pendingSet.has(u._id.toString())
    }));

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
// For private accounts: only owner or accepted followers can see the list.
export const getFollowing = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 100, 200);
    const skip = (page - 1) * limit;

    // Find user by uid, or by _id if uid looks like a MongoDB ObjectId
    let user = await User.findOne({ uid });
    if (!user && mongoose.Types.ObjectId.isValid(uid)) {
      user = await User.findById(uid);
    }
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const viewerId = req.user._id;
    const isOwner = viewerId.toString() === user._id.toString();

    const blockRelation = await Block.findOne({
      $or: [
        { blocker: viewerId, blocked: user._id },
        { blocker: user._id, blocked: viewerId },
      ],
    });
    if (blockRelation) {
      return res.status(403).json({
        success: false,
        message: 'Cannot view this profile',
      });
    }

    if (user.isPrivate && !isOwner) {
      const accepted = await Follow.findOne({
        follower: viewerId,
        following: user._id,
        status: 'accepted',
      });
      if (!accepted) {
        return res.json({
          success: true,
          following: [],
          restricted: true,
          pagination: { page: 1, limit, total: 0, pages: 0 },
        });
      }
    }

    const viewerBlockedIds = await Block.find({ $or: [{ blocker: viewerId }, { blocked: viewerId }] })
      .select('blocker blocked')
      .lean();
    const hideFromViewer = new Set();
    viewerBlockedIds.forEach((b) => {
      hideFromViewer.add(b.blocker.toString());
      hideFromViewer.add(b.blocked.toString());
    });
    hideFromViewer.delete(viewerId.toString());

    // Get following
    const follows = await Follow.find({
      follower: user._id,
      status: 'accepted'
    })
      .populate('following', 'uid username name avatar verified')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const followingList = follows
      .filter((f) => f.following && !hideFromViewer.has(f.following._id.toString()))
      .map((f) => ({ user: f.following.toObject(), followedAt: f.createdAt }));

    const followingIds = followingList.map((f) => f.user._id);
    const viewerFollowingAccepted = await Follow.find({
      follower: viewerId,
      following: { $in: followingIds },
      status: 'accepted'
    }).select('following').lean();
    const viewerFollowPending = await Follow.find({
      follower: viewerId,
      following: { $in: followingIds },
      status: 'pending'
    }).select('following').lean();
    const acceptedSet = new Set(
      viewerFollowingAccepted.map((f) => (f.following && f.following.toString ? f.following.toString() : String(f.following)))
    );
    const pendingSet = new Set(
      viewerFollowPending.map((f) => (f.following && f.following.toString ? f.following.toString() : String(f.following)))
    );

    // When viewing your own following list, everyone in the list is someone you follow
    const following = followingList.map(({ user: u, followedAt }) => {
      const uidStr = u._id != null ? u._id.toString() : '';
      const isFollowing = isOwner ? true : acceptedSet.has(uidStr);
      const isFollowPending = isOwner ? false : pendingSet.has(uidStr);
      return {
        ...u,
        followedAt,
        isFollowing,
        isFollowPending
      };
    });

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

// @desc    Get users I have sent a follow request to (outgoing pending) - for consistent "Requested" UI
// @route   GET /api/users/me/pending-following
// @access  Private
export const getMyPendingFollowing = async (req, res, next) => {
  try {
    const currentUserId = req.user._id;
    const follows = await Follow.find({
      follower: currentUserId,
      status: 'pending'
    })
      .select('following')
      .lean();
    const userIds = follows.map((f) => (f.following && f.following.toString ? f.following.toString() : String(f.following)));
    return res.json({
      success: true,
      userIds
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get pending follow requests to current user
// @route   GET /api/users/me/follow-requests
// @access  Private
export const getMyFollowRequests = async (req, res, next) => {
  try {
    const currentUserId = req.user._id;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const skip = (page - 1) * limit;

    const follows = await Follow.find({
      following: currentUserId,
      status: 'pending'
    })
      .populate('follower', 'uid username name avatar verified')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const requests = follows
      .filter((f) => f.follower)
      .map((f) => ({
        ...f.follower.toObject(),
        requestedAt: f.createdAt,
        followId: f._id
      }));

    const total = await Follow.countDocuments({
      following: currentUserId,
      status: 'pending'
    });

    res.json({
      success: true,
      requests,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Accept a follow request (uid = requester who sent the request)
// @route   POST /api/users/:uid/follow-request/accept
// @access  Private
export const acceptFollowRequest = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const currentUserId = req.user._id;

    const requester = await User.findOne({ uid });
    if (!requester) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const follow = await Follow.findOne({
      follower: requester._id,
      following: currentUserId,
      status: 'pending'
    });
    if (!follow) {
      return res.status(404).json({
        success: false,
        message: 'No pending follow request from this user'
      });
    }

    follow.status = 'accepted';
    await follow.save();

    await User.findByIdAndUpdate(currentUserId, { $inc: { followersCount: 1 } });
    await User.findByIdAndUpdate(requester._id, { $inc: { followingCount: 1 } });

    await createNotification({
      userId: requester._id,
      actorId: currentUserId,
      type: 'follow_accept',
      entityId: currentUserId,
      entityType: 'user',
      meta: { followId: follow._id.toString() }
    });

    res.json({
      success: true,
      message: 'Follow request accepted',
      follow: { id: follow._id, status: 'accepted' }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Decline a follow request (uid = requester who sent the request)
// @route   POST /api/users/:uid/follow-request/decline
// @access  Private
export const declineFollowRequest = async (req, res, next) => {
  try {
    const { uid } = req.params;
    const currentUserId = req.user._id;

    const requester = await User.findOne({ uid });
    if (!requester) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const follow = await Follow.findOneAndDelete({
      follower: requester._id,
      following: currentUserId,
      status: 'pending'
    });
    if (!follow) {
      return res.status(404).json({
        success: false,
        message: 'No pending follow request from this user'
      });
    }

    res.json({
      success: true,
      message: 'Follow request declined'
    });
  } catch (error) {
    next(error);
  }
};

export const deleteMyAccount = async (req, res, next) => {
  try {
    const userId = req.user._id;

    // Remove relations so no orphaned documents remain
    await Follow.deleteMany({ $or: [{ follower: userId }, { following: userId }] });
    await Block.deleteMany({ $or: [{ blocker: userId }, { blocked: userId }] });
    await Mute.deleteMany({ $or: [{ muter: userId }, { muted: userId }] });
    await CloseFriend.deleteMany({ $or: [{ owner: userId }, { friend: userId }] });

    await User.findByIdAndDelete(userId);

    return res.json({ success: true, message: "Account deleted successfully" });
  } catch (err) {
    next(err);
  }
};

// @desc    Get suggested users for explore (users to follow)
// @route   GET /api/users/suggestions
// @access  Private
export const getSuggestions = async (req, res, next) => {
  try {
    const currentUserId = req.user._id;
    const limit = parseInt(req.query.limit) || 10;

    const following = await Follow.find({ follower: currentUserId, status: 'accepted' })
      .select('following')
      .lean();
    const followingIds = following.map((f) => f.following);

    const asBlocker = await Block.find({ blocker: currentUserId }).select('blocked').lean();
    const asBlocked = await Block.find({ blocked: currentUserId }).select('blocker').lean();
    const blockedIds = [
      ...asBlocker.map((b) => b.blocked),
      ...asBlocked.map((b) => b.blocker),
    ];
    const excludeIds = [currentUserId, ...followingIds, ...blockedIds];

    const users = await User.find({
      _id: { $nin: excludeIds }
    })
      .select('uid username name avatar bio verified followersCount followingCount isPrivate')
      .sort({ followersCount: -1, createdAt: -1 })
      .limit(limit)
      .lean();

    const userIds = users.map((u) => u._id);
    const [acceptedDocs, pendingDocs] = await Promise.all([
      Follow.find({ follower: currentUserId, following: { $in: userIds }, status: 'accepted' }).select('following').lean(),
      Follow.find({ follower: currentUserId, following: { $in: userIds }, status: 'pending' }).select('following').lean(),
    ]);
    const acceptedSet = new Set(acceptedDocs.map((f) => f.following.toString()));
    const pendingSet = new Set(pendingDocs.map((f) => f.following.toString()));

    const usersWithStatus = users.map((u) => ({
      ...u,
      isFollowing: acceptedSet.has(u._id.toString()),
      isFollowPending: pendingSet.has(u._id.toString()),
    }));

    res.json({ success: true, users: usersWithStatus });
  } catch (error) {
    next(error);
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

    // Search users by username or name; exclude blocked users (either direction)
    const searchRegex = new RegExp(q.trim(), 'i');
    const currentUserId = req.user._id;
    const asBlocker = await Block.find({ blocker: currentUserId }).select('blocked').lean();
    const asBlocked = await Block.find({ blocked: currentUserId }).select('blocker').lean();
    const blockedIds = [
      ...asBlocker.map((b) => b.blocked),
      ...asBlocked.map((b) => b.blocker),
    ];
    const baseQuery = {
      $or: [
        { username: searchRegex },
        { name: searchRegex }
      ],
      ...(blockedIds.length ? { _id: { $nin: blockedIds } } : {}),
    };

    const users = await User.find(baseQuery)
      .select('uid username name avatar bio verified followersCount followingCount postsCount')
      .sort({ followersCount: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await User.countDocuments(baseQuery);

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
// For private accounts: returns posts only if viewer is owner or has accepted follow.
export const getUserPosts = async (req, res, next) => {
  try {
    const { uid } = req.params;
    if (!uid) {
      return res.status(400).json({
        success: false,
        message: 'User identifier is required',
      });
    }

    // Find user by uid (string) or by _id (MongoDB ObjectId string)
    let user = await User.findOne({ uid });
    if (!user && mongoose.Types.ObjectId.isValid(uid)) {
      user = await User.findById(uid);
    }
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const viewerId = req.user._id;
    const isOwner = viewerId.toString() === user._id.toString();

    // Block: if either has blocked the other, return no posts
    const blocked = await Block.findOne({
      $or: [
        { blocker: viewerId, blocked: user._id },
        { blocker: user._id, blocked: viewerId },
      ],
    });
    if (blocked) {
      return res.json({ success: true, posts: [] });
    }

    // Private account: allow only owner or accepted followers
    if (user.isPrivate && !isOwner) {
      const accepted = await Follow.findOne({
        follower: viewerId,
        following: user._id,
        status: 'accepted',
      });
      if (!accepted) {
        return res.json({ success: true, posts: [] });
      }
    }

    const posts = await Post.find({
      uid: user._id,
      isDeleted: false,
    })
      .populate('originalPostId', 'uid username type text media createdAt repostsCount')
      .sort({ createdAt: -1 });

    return res.json({
      success: true,
      posts,
    });
  } catch (error) {
    next(error);
  }
};
