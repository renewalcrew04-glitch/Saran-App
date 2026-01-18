import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema(
  {
    uid: {
      type: String,
      required: true,
      unique: true,
      index: true
    },
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
      index: true
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },
    password: {
      type: String,
      required: true,
      minlength: 6,
      select: false // Don't return password by default
    },
    name: {
      type: String,
      required: true,
      trim: true
    },
    avatar: {
      type: String,
      default: null
    },
    bio: {
      type: String,
      maxlength: 500,
      default: ''
    },
    isPrivate: {
      type: Boolean,
      default: false
    },
    profileCompleted: {
      type: Boolean,
      default: false
    },
    verified: {
      type: Boolean,
      default: false
    },
    verificationStatus: {
      type: String,
      enum: ['pending', 'verified', 'rejected'],
      default: 'pending'
    },
    expoPushToken: {
      type: String,
      default: null
    },
    followersCount: {
      type: Number,
      default: 0
    },
    followingCount: {
      type: Number,
      default: 0
    },
    postsCount: {
      type: Number,
      default: 0
    },
    wellnessStreak: {
      type: Number,
      default: 0
    },
    lastWellnessActivity: {
      type: Date,
      default: null
    }
  },
  {
    timestamps: true, // Adds createdAt and updatedAt
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
  }
);

// Index for search
userSchema.index({ username: 'text', name: 'text' });

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Generate unique UID if not provided
userSchema.pre('save', async function (next) {
  if (!this.uid) {
    this.uid = this._id.toString();
  }
  next();
});

// Compare password method
userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// Virtual for user relations (followers, following, etc.)
userSchema.virtual('followers', {
  ref: 'Follow',
  localField: '_id',
  foreignField: 'following'
});

userSchema.virtual('following', {
  ref: 'Follow',
  localField: '_id',
  foreignField: 'follower'
});

const User = mongoose.model('User', userSchema);

export default User;
