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

// Username validation: alphanumeric + underscore, 3–30 chars
const USERNAME_REGEX = /^[a-z0-9_]{3,30}$/;

/** Check username availability (public) */
export const checkUsernameAvailability = async (req, res) => {
  try {
    const raw = (req.body?.username ?? req.query?.username ?? '').toString().trim().toLowerCase();
    if (!raw) {
      return res.status(400).json({ available: false, valid: false, message: 'Username is required' });
    }
    if (!USERNAME_REGEX.test(raw)) {
      return res.status(200).json({
        available: false,
        valid: false,
        message: 'Use 3–30 characters: letters, numbers, and underscores only',
      });
    }
    const existing = await User.findOne({ username: raw });
    return res.status(200).json({
      available: !existing,
      valid: true,
      message: existing ? 'Username is taken' : 'Username is available',
    });
  } catch (e) {
    return res.status(500).json({ available: false, valid: false, message: 'Could not check username' });
  }
};

/** Get suggested usernames when base is taken (public) */
export const getUsernameSuggestions = async (req, res) => {
  try {
    const raw = (req.body?.username ?? req.query?.username ?? '').toString().trim().toLowerCase();
    const base = raw.replace(/[^a-z0-9_]/g, '').slice(0, 20) || 'user';
    const suggestions = [];
    const rnd = () => Math.floor(Math.random() * 900) + 100;
    const candidates = [
      `${base}${rnd()}`,
      `${base}_${rnd().toString().slice(-2)}`,
      `${base}${new Date().getFullYear().toString().slice(-2)}`,
      `the_${base}`,
      `${base}_${Math.random().toString(36).slice(2, 6)}`,
    ];
    for (const s of candidates) {
      if (suggestions.length >= 4) break;
      const norm = s.toLowerCase().replace(/[^a-z0-9_]/g, '');
      if (norm.length < 3 || norm.length > 30) continue;
      const exists = await User.findOne({ username: norm });
      if (!exists && !suggestions.includes(norm)) suggestions.push(norm);
    }
    return res.status(200).json({ suggestions });
  } catch (e) {
    return res.status(500).json({ suggestions: [] });
  }
};

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
    let { username, email, password, name, gender, dob, selfieImage } = req.body;

    // Validation
    if (!username || !email || !password || !name) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields'
      });
    }

    // Normalize: username is unique case-insensitively (lowercase + trim)
    const usernameNorm = (typeof username === 'string' ? username : String(username)).trim().toLowerCase();
    const emailNorm = (typeof email === 'string' ? email : String(email)).trim().toLowerCase();
    if (!usernameNorm) {
      return res.status(400).json({
        success: false,
        message: 'Username is required'
      });
    }

    // Check if email already registered
    const existingEmail = await User.findOne({ email: emailNorm });
    if (existingEmail) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered'
      });
    }

    // Check if username already taken (usernames are stored lowercase in schema)
    const existingUsername = await User.findOne({ username: usernameNorm });
    if (existingUsername) {
      return res.status(400).json({
        success: false,
        message: 'Username already taken'
      });
    }

    // Create user (uid will be auto-generated in pre-save hook). Use normalized username.
    const user = await User.create({
      username: usernameNorm,
      email: emailNorm,
      password,
      name: (name || '').trim() || name,
      gender,
      dob,
      selfieImage,
      verificationStatus: 'pending'
    });

    // ---------------- FAKE AI VERIFICATION ----------------
const aiApproved = Math.random() < 0.8;

if (aiApproved) {
  user.verificationStatus = 'verified';
  user.verified = true;
  await user.save();
} else {
  user.verificationStatus = 'pending';
  await user.save();
}
// -----------------------------------------------------

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
    // MongoDB duplicate key (e.g. username or email already exists)
    if (error.code === 11000 && error.keyPattern) {
      const msg = error.keyPattern.username
        ? 'Username already taken'
        : error.keyPattern.email
          ? 'Email already registered'
          : 'An account with this value already exists';
      return res.status(400).json({ success: false, message: msg });
    }
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

    if (user.gender === 'male') {
  return res.status(403).json({
    success: false,
    message: 'SARAN is exclusively for Women.'
  });
}

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
        locationText: user.locationText,
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
        locationText: user.locationText,
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
    const { name, bio, locationText, avatar, isPrivate } = req.body;

    const user = await User.findById(req.user._id);

    if (name) user.name = name;
    if (bio !== undefined) user.bio = bio;
    if (locationText !== undefined) user.locationText = locationText;
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
        locationText: updatedUser.locationText,
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
