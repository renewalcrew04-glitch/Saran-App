import jwt from 'jsonwebtoken';
import Follow from '../models/Follow.model.js';
import User from '../models/User.model.js';

/** Count unique users who follow this user (accepted only). Duplicate Follow rows count as 1. */
async function countDistinctFollowers(userId) {
  const result = await Follow.aggregate([
    { $match: { following: userId, status: 'accepted' } },
    { $group: { _id: '$follower' } },
    { $count: 'count' },
  ]);
  return result[0]?.count ?? 0;
}

/** Count unique users this user follows (accepted only). Duplicate Follow rows count as 1. */
async function countDistinctFollowing(userId) {
  const result = await Follow.aggregate([
    { $match: { follower: userId, status: 'accepted' } },
    { $group: { _id: '$following' } },
    { $count: 'count' },
  ]);
  return result[0]?.count ?? 0;
}

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'your-secret-key', {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
export const register = async (req, res, next) => {
  try {
    const { username, email, password, name } = req.body;

    // Validation
    if (!username || !email || !password || !name) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields'
      });
    }

    // Check if user exists
    const userExists = await User.findOne({ $or: [{ email }, { username }] });
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'User already exists'
      });
    }

    // Create user (uid will be auto-generated in pre-save hook)
    const user = await User.create({
      username,
      email,
      password,
      name
    });

    // Ensure uid is set (in case pre-save didn't run)
    if (!user.uid && user._id) {
      user.uid = user._id.toString();
      await user.save();
    }

    if (user) {
      res.status(201).json({
        success: true,
        token: generateToken(user._id),
        user: {
          uid: user.uid || user._id.toString(),
          username: user.username,
          email: user.email,
          name: user.name,
          avatar: user.avatar,
          bio: user.bio
        }
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid user data'
      });
    }
  } catch (error) {
    next(error);
  }
};

// @desc    Authenticate a user
// @route   POST /api/auth/login
// @access  Public
export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Check for user
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if password matches
    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const uidValue = user.uid || user._id.toString();

    // Live counts: distinct followers/following so duplicates don't inflate the number
    const [followersCount, followingCount] = await Promise.all([
      countDistinctFollowers(user._id),
      countDistinctFollowing(user._id),
    ]);

    res.json({
      success: true,
      token: generateToken(user._id),
      user: {
        uid: uidValue,
        username: user.username,
        email: user.email,
        name: user.name,
        avatar: user.avatar,
        bio: user.bio,
        coverImage: user.coverImage,
        profileCompleted: user.profileCompleted,
        verified: user.verified,
        followersCount,
        followingCount,
        postsCount: user.postsCount ?? 0,
        wellnessStreak: user.wellnessStreak ?? 0
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current logged in user
// @route   GET /api/auth/me
// @access  Private
export const getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);

    // Ensure uid is always sent (fallback to _id for old users without uid)
    const uidValue = user.uid || user._id.toString();

    // Live counts: distinct followers/following so duplicates don't inflate the number
    const [followersCount, followingCount] = await Promise.all([
      countDistinctFollowers(req.user._id),
      countDistinctFollowing(req.user._id),
    ]);

    res.json({
      success: true,
      user: {
        uid: uidValue,
        username: user.username,
        email: user.email,
        name: user.name,
        avatar: user.avatar,
        bio: user.bio,
        coverImage: user.coverImage,
        profileCompleted: user.profileCompleted,
        verified: user.verified,
        followersCount,
        followingCount,
        postsCount: user.postsCount ?? 0,
        wellnessStreak: user.wellnessStreak ?? 0
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
export const updateProfile = async (req, res, next) => {
  try {
    const { name, bio, avatar, isPrivate } = req.body;

    const user = await User.findById(req.user._id);

    if (name) user.name = name;
    if (bio !== undefined) user.bio = bio;
    if (avatar !== undefined) user.avatar = avatar;
    if (isPrivate !== undefined) user.isPrivate = isPrivate;

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
        profileCompleted: updatedUser.profileCompleted
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Logout user
// @route   POST /api/auth/logout
// @access  Private
export const logout = async (req, res, next) => {
  try {
    // In JWT-based auth, logout is handled client-side by removing token
    // But you can add token blacklisting here if needed
    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    next(error);
  }
};
