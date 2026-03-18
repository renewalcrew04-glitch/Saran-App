import jwt from 'jsonwebtoken';
import OpenAI from 'openai';
import Follow from '../models/Follow.model.js';
import User from '../models/User.model.js';
import { sendOtpEmail } from '../services/email.service.js';
import { generateOtp, saveOtp, verifyOtp as checkOtp } from '../utils/otpStore.js';

// ─── OpenAI (for selfie verification) ────────────────────────────────────────
let _openai = null;
function getOpenAI() {
  if (!process.env.OPENAI_API_KEY) return null;
  if (!_openai) _openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  return _openai;
}

// ─── Validators ───────────────────────────────────────────────────────────────
const USERNAME_REGEX = /^[a-z0-9_]{3,30}$/;

// RFC-5322 simplified — catches obvious typos, allows all valid TLDs
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

// +91 optional, then 6-9 as first digit, then 9 more digits
const MOBILE_REGEX = /^(\+91[\s-]?)?[6-9]\d{9}$/;

function validateEmail(email) {
  return EMAIL_REGEX.test(email);
}

function normalizeMobile(raw) {
  // Strip +91, spaces, dashes — return bare 10-digit number or null
  if (!raw) return null;
  const stripped = raw.trim().replace(/^\+91[\s-]?/, '').replace(/[\s-]/g, '');
  return stripped;
}

function validateMobile(raw) {
  if (!raw) return true; // optional field
  return MOBILE_REGEX.test(raw.trim());
}

// Returns 'weak' | 'fair' | 'good' | 'strong'
function getPasswordStrength(password) {
  if (!password || password.length < 8) return 'weak';
  let score = 0;
  if (/[a-z]/.test(password)) score++;
  if (/[A-Z]/.test(password)) score++;
  if (/[0-9]/.test(password)) score++;
  if (/[^a-zA-Z0-9]/.test(password)) score++;
  if (score <= 1) return 'weak';
  if (score === 2) return 'fair';
  if (score === 3) return 'good';
  return 'strong';
}

// ─── Follower helpers ─────────────────────────────────────────────────────────
async function countDistinctFollowers(userId) {
  const result = await Follow.aggregate([
    { $match: { following: userId, status: 'accepted' } },
    { $group: { _id: '$follower' } },
    { $count: 'count' },
  ]);
  return result[0]?.count ?? 0;
}

async function countDistinctFollowing(userId) {
  const result = await Follow.aggregate([
    { $match: { follower: userId, status: 'accepted' } },
    { $group: { _id: '$following' } },
    { $count: 'count' },
  ]);
  return result[0]?.count ?? 0;
}

// ─── JWT ──────────────────────────────────────────────────────────────────────
const generateToken = (id) =>
  jwt.sign({ id }, process.env.JWT_SECRET || 'your-secret-key', {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

// ─── AI Selfie Verification ───────────────────────────────────────────────────
// Returns { approved: true } | { approved: false, reason: string } | { approved: null, reason: 'manual_review' }
async function verifySelfieWithAI(selfieImage) {
  try {
    const client = getOpenAI();
    if (!client) {
      // No API key — accept but mark pending for manual review
      return { approved: null, reason: 'manual_review' };
    }

    // Support both raw base64 and data URLs
    const imageUrl = selfieImage.startsWith('data:')
      ? selfieImage
      : `data:image/jpeg;base64,${selfieImage}`;

    const response = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: { url: imageUrl, detail: 'low' },
            },
            {
              type: 'text',
              text:
                'This image was submitted as a live selfie for a women-only app registration.\n\n' +
                'Reply with ONLY a valid JSON object, no other text:\n' +
                '{"live": true/false, "female": true/false}\n\n' +
                'live = Is this a real live selfie of a real human face? (false if: photo of a photo, screenshot, drawing, blurry, no face visible)\n' +
                'female = Does this person appear to be female or a transgender woman?',
            },
          ],
        },
      ],
      max_tokens: 30,
      temperature: 0,
    });

    const text = response?.choices?.[0]?.message?.content?.trim() || '{}';
    const match = text.match(/\{[^}]+\}/);
    if (!match) return { approved: false, reason: 'Could not analyze selfie. Please retake.' };

    const result = JSON.parse(match[0]);

    if (!result.live) {
      return { approved: false, reason: 'Please take a clear live selfie. Screenshots and photos of photos are not accepted.' };
    }
    if (!result.female) {
      return { approved: false, reason: 'SARAN is exclusively for women and trans women.' };
    }

    return { approved: true };
  } catch (e) {
    console.error('Selfie AI verification failed:', e.message);
    // On failure, allow through as pending for manual review
    return { approved: null, reason: 'manual_review' };
  }
}

// ─── Step Validators (called by the frontend per screen) ──────────────────────

// Step 1: username + profile name
// POST /api/auth/validate/step1
export const validateStep1 = async (req, res) => {
  try {
    const username = (req.body?.username || '').trim().toLowerCase();
    const name = (req.body?.name || '').trim();

    const errors = {};

    if (!username) {
      errors.username = 'Username is required';
    } else if (!USERNAME_REGEX.test(username)) {
      errors.username = 'Use 3–30 characters: letters, numbers, and underscores only';
    } else {
      const exists = await User.findOne({ username });
      if (exists) errors.username = 'Username is already taken';
    }

    if (!name) {
      errors.name = 'Profile name is required';
    } else if (name.length < 2) {
      errors.name = 'Name must be at least 2 characters';
    } else if (name.length > 60) {
      errors.name = 'Name must be under 60 characters';
    }

    if (Object.keys(errors).length) {
      return res.status(400).json({ success: false, errors });
    }

    return res.json({ success: true });
  } catch (e) {
    return res.status(500).json({ success: false, message: 'Validation error' });
  }
};

// Step 2: email + mobile (optional) + password
// POST /api/auth/validate/step2
export const validateStep2 = async (req, res) => {
  try {
    const email = (req.body?.email || '').trim().toLowerCase();
    const mobile = req.body?.mobile || null;
    const password = req.body?.password || '';

    const errors = {};

    if (!email) {
      errors.email = 'Email is required';
    } else if (!validateEmail(email)) {
      errors.email = 'Enter a valid email address';
    } else {
      const exists = await User.findOne({ email });
      if (exists) errors.email = 'This email is already registered';
    }

    if (mobile && !validateMobile(mobile)) {
      errors.mobile = 'Enter a valid 10-digit Indian mobile number';
    }

    const strength = getPasswordStrength(password);
    if (!password) {
      errors.password = 'Password is required';
    } else if (strength === 'weak') {
      errors.password = 'Password is too weak. Use at least 8 characters with a mix of letters and numbers.';
    }

    if (Object.keys(errors).length) {
      return res.status(400).json({ success: false, errors });
    }

    return res.json({ success: true, passwordStrength: strength });
  } catch (e) {
    return res.status(500).json({ success: false, message: 'Validation error' });
  }
};

// Step 3: date of birth
// POST /api/auth/validate/step3
export const validateStep3 = async (req, res) => {
  try {
    const { dob } = req.body;

    if (!dob) {
      return res.status(400).json({ success: false, errors: { dob: 'Date of birth is required' } });
    }

    const dobDate = new Date(dob);
    if (isNaN(dobDate.getTime())) {
      return res.status(400).json({ success: false, errors: { dob: 'Invalid date format' } });
    }

    const today = new Date();
    const age = today.getFullYear() - dobDate.getFullYear()
      - (today < new Date(today.getFullYear(), dobDate.getMonth(), dobDate.getDate()) ? 1 : 0);

    if (age < 13) {
      return res.status(400).json({ success: false, errors: { dob: 'You must be at least 13 years old to join' } });
    }

    return res.json({ success: true, age });
  } catch (e) {
    return res.status(500).json({ success: false, message: 'Validation error' });
  }
};

// Step 4: AI selfie verification
// POST /api/auth/verify-selfie
// Body: { selfieImage: string (base64 or data URL) }
export const verifySelfie = async (req, res) => {
  try {
    const { selfieImage } = req.body;

    if (!selfieImage) {
      return res.status(400).json({ success: false, message: 'Selfie image is required' });
    }

    const result = await verifySelfieWithAI(selfieImage);

    if (result.approved === false) {
      return res.status(422).json({ success: false, approved: false, message: result.reason });
    }

    // approved === true or null (manual review)
    return res.json({
      success: true,
      approved: result.approved ?? null,
      manualReview: result.reason === 'manual_review',
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: 'Selfie verification failed. Please try again.' });
  }
};

// ─── Username helpers ─────────────────────────────────────────────────────────

// GET /api/auth/username/check
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

// GET /api/auth/username/suggestions
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

// ─── Register ────────────────────────────────────────────────────────────────
// POST /api/auth/register
// Body: { username, name, email, mobile?, password, dob, selfieImage, gender, termsAccepted }
export const register = async (req, res, next) => {
  try {
    let { username, name, email, mobile, password, dob, selfieImage, gender, termsAccepted } = req.body;

    // ── Required field check ──────────────────────────────────────────────────
    const missing = [];
    if (!username) missing.push('username');
    if (!name) missing.push('name');
    if (!email) missing.push('email');
    if (!password) missing.push('password');
    if (!dob) missing.push('dob');
    if (!gender) missing.push('gender');

    if (missing.length) {
      return res.status(400).json({ success: false, message: `Missing required fields: ${missing.join(', ')}` });
    }

    // ── Gender must be female or trans_woman ──────────────────────────────────
    if (!['female', 'trans_woman'].includes(gender)) {
      return res.status(403).json({ success: false, message: 'SARAN is exclusively for women and trans women' });
    }

    // ── Normalize ─────────────────────────────────────────────────────────────
    const usernameNorm = String(username).trim().toLowerCase();
    const emailNorm = String(email).trim().toLowerCase();
    const nameNorm = String(name).trim();
    const mobileNorm = mobile ? normalizeMobile(mobile) : null;

    // ── Username format ───────────────────────────────────────────────────────
    if (!USERNAME_REGEX.test(usernameNorm)) {
      return res.status(400).json({ success: false, message: 'Username: 3–30 characters, letters, numbers and underscores only' });
    }

    // ── Email format ──────────────────────────────────────────────────────────
    if (!validateEmail(emailNorm)) {
      return res.status(400).json({ success: false, message: 'Enter a valid email address' });
    }

    // ── Mobile format (if provided) ───────────────────────────────────────────
    if (mobile && !validateMobile(mobile)) {
      return res.status(400).json({ success: false, message: 'Enter a valid 10-digit Indian mobile number' });
    }

    // ── Password strength ─────────────────────────────────────────────────────
    const strength = getPasswordStrength(password);
    if (strength === 'weak') {
      return res.status(400).json({
        success: false,
        message: 'Password is too weak. Use at least 8 characters with a mix of letters, numbers, and symbols.',
        passwordStrength: 'weak',
      });
    }

    // ── DOB age check ─────────────────────────────────────────────────────────
    const dobDate = new Date(dob);
    if (isNaN(dobDate.getTime())) {
      return res.status(400).json({ success: false, message: 'Invalid date of birth' });
    }
    const today = new Date();
    const age = today.getFullYear() - dobDate.getFullYear()
      - (today < new Date(today.getFullYear(), dobDate.getMonth(), dobDate.getDate()) ? 1 : 0);
    if (age < 13) {
      return res.status(400).json({ success: false, message: 'You must be at least 13 years old to join' });
    }

    // ── Duplicate checks ──────────────────────────────────────────────────────
    const [existingEmail, existingUsername] = await Promise.all([
      User.findOne({ email: emailNorm }),
      User.findOne({ username: usernameNorm }),
    ]);
    if (existingEmail) return res.status(400).json({ success: false, message: 'Email already registered' });
    if (existingUsername) return res.status(400).json({ success: false, message: 'Username already taken' });

    // ── AI selfie verification ────────────────────────────────────────────────
    let verificationStatus = 'pending';
    let verified = false;

    if (selfieImage) {
      const selfieResult = await verifySelfieWithAI(selfieImage);
      if (selfieResult.approved === false) {
        return res.status(422).json({ success: false, message: selfieResult.reason });
      }
      if (selfieResult.approved === true) {
        verificationStatus = 'verified';
        verified = true;
      }
      // approved === null → manual review, stays 'pending'
    }

    // ── Create user ───────────────────────────────────────────────────────────
    const user = await User.create({
      username: usernameNorm,
      name: nameNorm,
      email: emailNorm,
      mobile: mobileNorm,
      password,
      dob: dobDate,
      selfieImage: selfieImage || null,
      gender,
      termsAccepted: true,
      verificationStatus,
      verified,
    });

    return res.status(201).json({
      success: true,
      token: generateToken(user._id),
      user: {
        uid: user.uid || user._id.toString(),
        username: user.username,
        email: user.email,
        name: user.name,
        avatar: user.avatar,
        verified: user.verified,
        verificationStatus: user.verificationStatus,
        gender: user.gender,
        dob: user.dob,
      },
    });
  } catch (error) {
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

// ─── Login ────────────────────────────────────────────────────────────────────
// POST /api/auth/login
export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide email and password' });
    }

    // Find user first, then check gender
    const user = await User.findOne({ email: email.trim().toLowerCase() }).select('+password');

    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // Block male users (should not exist post-registration, but guard anyway)
    if (user.gender === 'male') {
      return res.status(403).json({ success: false, message: 'SARAN is exclusively for Women.' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const uidValue = user.uid || user._id.toString();

    const [followersCount, followingCount] = await Promise.all([
      countDistinctFollowers(user._id),
      countDistinctFollowing(user._id),
    ]);

    return res.json({
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
        verificationStatus: user.verificationStatus,
        followersCount,
        followingCount,
        postsCount: user.postsCount ?? 0,
        wellnessStreak: user.wellnessStreak ?? 0,
        gender: user.gender,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ─── Get current user ─────────────────────────────────────────────────────────
export const getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    const uidValue = user.uid || user._id.toString();

    const [followersCount, followingCount] = await Promise.all([
      countDistinctFollowers(req.user._id),
      countDistinctFollowing(req.user._id),
    ]);

    return res.json({
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
        verificationStatus: user.verificationStatus,
        followersCount,
        followingCount,
        postsCount: user.postsCount ?? 0,
        wellnessStreak: user.wellnessStreak ?? 0,
        gender: user.gender ?? null,
        dob: user.dob ? user.dob.toISOString?.() ?? user.dob : null,
        selfieImage: user.selfieImage ?? null,
        mobile: user.mobile ?? null,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ─── Update profile ───────────────────────────────────────────────────────────
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

    return res.json({
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
        profileCompleted: updatedUser.profileCompleted,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ─── Logout ───────────────────────────────────────────────────────────────────
export const logout = async (req, res, next) => {
  try {
    return res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    next(error);
  }
};

// ─── OTP (disabled — will be re-enabled later) ───────────────────────────────
export const sendOtp = async (req, res) => {
  // OTP email verification is temporarily disabled
  return res.json({ success: true, message: 'OTP sent to your email' });
};

export const verifyOtp = async (req, res) => {
  // OTP email verification is temporarily disabled — always passes
  return res.json({ success: true, message: 'Email verified successfully' });
};

// ─── Password strength check (utility for frontend) ──────────────────────────
// GET /api/auth/password-strength?password=...
export const checkPasswordStrength = (req, res) => {
  const password = req.query?.password || req.body?.password || '';
  const strength = getPasswordStrength(password);
  const tips = {
    weak: 'Add more characters, uppercase letters, numbers, and symbols',
    fair: 'Add uppercase letters or symbols to make it stronger',
    good: 'Almost there — add a symbol to make it strong',
    strong: 'Great password!',
  };
  return res.json({ strength, tip: tips[strength] });
};
