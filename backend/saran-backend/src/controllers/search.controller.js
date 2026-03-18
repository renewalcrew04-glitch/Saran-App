import Post from '../models/Post.model.js';
import User from '../models/User.model.js';
import Follow from '../models/Follow.model.js';

const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const getQueryMeta = (req) => {
  const q = (req.query.q || '').toString().trim();
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const skip = (page - 1) * limit;
  return { q, limit, skip };
};

const findUsers = async (q, limit, skip) => {
  if (!q) return [];
  const regex = new RegExp(escapeRegex(q), 'i');
  return User.find({
    $or: [{ username: regex }, { name: regex }],
  })
    .select('uid username name avatar bio followersCount followingCount verified')
    .limit(limit)
    .skip(skip)
    .lean();
};

const findPosts = async (q, limit, skip) => {
  if (!q) return [];
  const baseFilter = { visibility: 'public', isDeleted: false };
  const tag = q.startsWith('#') ? q.slice(1).trim() : '';
  const regex = new RegExp(escapeRegex(tag || q), 'i');

  let filter;
  if (tag) {
    filter = { ...baseFilter, hashtags: regex };
  } else {
    filter = { ...baseFilter, $or: [{ text: regex }, { hashtags: regex }] };
  }

  return Post.find(filter)
    .sort({ createdAt: -1 })
    .limit(limit)
    .skip(skip)
    .populate('uid', 'name avatar verified')
    .lean();
};

const addFollowStatus = async (users, currentUserId) => {
  if (!users.length || !currentUserId) return users;
  const userIds = users.map((u) => u._id);
  const [acceptedDocs, pendingDocs] = await Promise.all([
    Follow.find({ follower: currentUserId, following: { $in: userIds }, status: 'accepted' }).select('following').lean(),
    Follow.find({ follower: currentUserId, following: { $in: userIds }, status: 'pending' }).select('following').lean(),
  ]);
  const acceptedSet = new Set(acceptedDocs.map((f) => f.following.toString()));
  const pendingSet = new Set(pendingDocs.map((f) => f.following.toString()));
  return users.map((u) => ({
    ...u,
    isFollowing: acceptedSet.has(u._id.toString()),
    isFollowPending: pendingSet.has(u._id.toString()),
  }));
};

export const searchUsers = async (req, res, next) => {
  try {
    const { q, limit, skip } = getQueryMeta(req);
    let users = await findUsers(q, limit, skip);
    if (req.user && req.user._id) {
      users = await addFollowStatus(users, req.user._id);
    }
    res.json({ success: true, users });
  } catch (error) {
    console.error('searchUsers error:', error);
    res.json({ success: true, users: [] });
  }
};

export const searchPosts = async (req, res, next) => {
  try {
    const { q, limit, skip } = getQueryMeta(req);
    const posts = await findPosts(q, limit, skip);

    res.json({ success: true, posts });
  } catch (error) {
    console.error('searchPosts error:', error);
    res.json({ success: true, posts: [] });
  }
};

export const searchAll = async (req, res, next) => {
  try {
    const { q, limit, skip } = getQueryMeta(req);
    if (!q) return res.json({ success: true, users: [], posts: [] });

    let [users, posts] = await Promise.all([
      findUsers(q, Math.min(limit, 10), skip),
      findPosts(q, limit, skip),
    ]);
    if (req.user && req.user._id && users.length) {
      users = await addFollowStatus(users, req.user._id);
    }

    res.json({ success: true, users, posts });
  } catch (error) {
    console.error('searchAll error:', error);
    res.json({ success: true, users: [], posts: [] });
  }
};
