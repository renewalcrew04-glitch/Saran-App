import Comment from '../models/Comment.model.js';
import Like from '../models/Like.model.js';
import Post from '../models/Post.model.js';
import User from '../models/User.model.js';
import { createNotification } from "../services/notification.service.js";

// @desc    Create a new post
// @route   POST /api/posts
// @access  Private

export const createPost = async (req, res, next) => {
  try {
    const {
      text = '',
      media = [],
      thumbnail = null,
      visibility = 'public',
      category = null,
      hashtags = [],
      mentions = [],
      isQuote = false,
      originalPostId = null,
    } = req.body;

    const userId = req.user?._id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // ✅ PERMANENT FIX: infer type
    let type = 'text';
    if (Array.isArray(media) && media.length > 0) {
      type = media[0].endsWith('.mp4') ? 'video' : 'photo';
    }

    const post = await Post.create({
      uid: user._id,
      username: user.username,
      type,                    // ✅ FIXED
      text,
      media: Array.isArray(media) ? media : [],
      thumbnail,
      visibility,
      category,
      hashtags: Array.isArray(hashtags) ? hashtags : [],
      mentions: Array.isArray(mentions) ? mentions : [],
      isQuote,
      originalPostId,
    });

    await User.findByIdAndUpdate(user._id, {
      $inc: { postsCount: 1 },
    });

    return res.status(201).json({
      success: true,
      post,
    });
  } catch (error) {
    console.error('CREATE POST ERROR ❌', error);
    next(error);
  }
};

// @desc    Get a single post
// @route   GET /api/posts/:id
// @access  Private
export const getPost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const post = await Post.findById(id)
      .populate('uid', 'uid username name avatar verified')
      .populate('originalPostId', 'uid username type text media createdAt');

    if (!post || post.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Check if user liked this post
    const like = await Like.findOne({
      uid: userId,
      post: post._id
    });
    const isLiked = !!like;

    res.json({
      success: true,
      post: {
        ...post.toObject(),
        isLiked
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update a post
// @route   PUT /api/posts/:id
// @access  Private (post owner only)
export const updatePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;
    const { text, media, visibility, category, hashtags } = req.body;

    const post = await Post.findById(id);

    if (!post || post.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Check if user owns the post
    if (post.uid.toString() !== userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this post'
      });
    }

    // Update fields
    if (text !== undefined) post.text = text;
    if (media !== undefined) post.media = media;
    if (visibility !== undefined) post.visibility = visibility;
    if (category !== undefined) post.category = category;
    if (hashtags !== undefined) post.hashtags = hashtags;

    const updatedPost = await post.save();

    res.json({
      success: true,
      post: updatedPost
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a post (soft delete)
// @route   DELETE /api/posts/:id
// @access  Private (post owner only)
export const deletePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const post = await Post.findById(id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Check if user owns the post
    if (post.uid.toString() !== userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this post'
      });
    }

    // Soft delete
    post.isDeleted = true;
    await post.save();

    // Update user's post count
    await User.findByIdAndUpdate(userId, {
      $inc: { postsCount: -1 }
    });

    res.json({
      success: true,
      message: 'Post deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Like a post
// @route   POST /api/posts/:id/like
// @access  Private
export const likePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const post = await Post.findById(id);

    if (!post || post.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Check if already liked
    const existingLike = await Like.findOne({
      uid: userId,
      post: post._id
    });

    if (existingLike) {
      return res.status(400).json({
        success: false,
        message: 'Post already liked'
      });
    }

    // Create like
    await Like.create({
      uid: userId,
      post: post._id
    });

    // Update post likes count
    post.likesCount += 1;
    await post.save();

    // Create notification for post owner
    if (post.uid.toString() !== userId.toString()) {
  await createNotification({
    userId: post.uid,
    actorId: userId,
    type: "like",
    entityId: post._id,
    entityType: "post",
  });
}
    res.json({
      success: true,
      message: 'Post liked successfully',
      likesCount: post.likesCount
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Post already liked'
      });
    }
    next(error);
  }
};

// @desc    Unlike a post
// @route   DELETE /api/posts/:id/like
// @access  Private
export const unlikePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const post = await Post.findById(id);

    if (!post || post.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Find and delete like
    const like = await Like.findOneAndDelete({
      uid: userId,
      post: post._id
    });

    if (!like) {
      return res.status(400).json({
        success: false,
        message: 'Post not liked'
      });
    }

    // Update post likes count
    post.likesCount = Math.max(0, post.likesCount - 1);
    await post.save();

    res.json({
      success: true,
      message: 'Post unliked successfully',
      likesCount: post.likesCount
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Repost a post
// @route   POST /api/posts/:id/repost
// @access  Private
export const repost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const originalPost = await Post.findById(id);

    if (!originalPost || originalPost.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Create notification for post owner
    if (originalPost.uid.toString() !== userId.toString()) {
  await createNotification({
    userId: originalPost.uid,
    actorId: userId,
    type: "repost",
    entityId: originalPost._id,
    entityType: "post",
  });
}

    // Check if already reposted
    const existingRepost = await Post.findOne({
      uid: userId,
      type: 'repost',
      originalPostId: originalPost._id,
      isDeleted: false
    });

    if (existingRepost) {
      return res.status(400).json({
        success: false,
        message: 'Post already reposted'
      });
    }

    // Get user info
    const user = await User.findById(userId);

    // Create repost
    const repost = await Post.create({
      uid: userId,
      username: user.username,
      type: 'repost',
      originalPostId: originalPost._id,
      text: '',
      media: []
    });

    // Update original post reposts count
    originalPost.repostsCount += 1;
    await originalPost.save();

    res.status(201).json({
      success: true,
      message: 'Post reposted successfully',
      repost: {
        id: repost._id,
        originalPost: originalPost,
        repostsCount: originalPost.repostsCount
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Quote repost a post
// @route   POST /api/posts/:id/quote
// @access  Private
export const quotePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { text, media } = req.body;
    const userId = req.user._id;

    const originalPost = await Post.findById(id);

    if (!originalPost || originalPost.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Create notification for post owner
    if (originalPost.uid.toString() !== userId.toString()) {
  await createNotification({
    userId: originalPost.uid,
    actorId: userId,
    type: "quote",
    entityId: originalPost._id,
    entityType: "post",
  });
}

    // Get user info
    const user = await User.findById(userId);

    // Create quote post
    const quotePost = await Post.create({
      uid: userId,
      username: user.username,
      type: 'quote',
      isQuote: true,
      originalPostId: originalPost._id,
      text: text || '',
      media: media || []
    });

    // Update original post reposts count
    originalPost.repostsCount += 1;
    await originalPost.save();

    // Update user's post count
    await User.findByIdAndUpdate(userId, {
      $inc: { postsCount: 1 }
    });

    res.status(201).json({
      success: true,
      message: 'Post quoted successfully',
      post: {
        id: quotePost._id,
        text: quotePost.text,
        media: quotePost.media,
        originalPost: originalPost,
        repostsCount: originalPost.repostsCount
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get post comments
// @route   GET /api/posts/:id/comments
// @access  Private
export const getComments = async (req, res, next) => {
  try {
    const { id } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const post = await Post.findById(id);

    if (!post || post.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Get top-level comments (no parent)
    const comments = await Comment.find({
      post: post._id,
      parentComment: null,
      isDeleted: false
    })
      .populate('uid', 'uid username name avatar verified')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Get total count
    const total = await Comment.countDocuments({
      post: post._id,
      parentComment: null,
      isDeleted: false
    });

    res.json({
      success: true,
      comments,
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

export const toggleHideLikeCount = async (req, res, next) => {
  try {
    const uid = req.user._id;
    const { postId } = req.params;

    const post = await Post.findOne({ _id: postId, uid });
    if (!post) {
      return res.status(404).json({ success: false });
    }

    post.hideLikeCount = !post.hideLikeCount;
    await post.save();

    res.json({
      success: true,
      hideLikeCount: post.hideLikeCount,
    });
  } catch (err) {
    next(err);
  }
};

export const editPost = async (req, res, next) => {
  try {
    const uid = req.user._id;
    const { postId } = req.params;
    const { text } = req.body;

    const post = await Post.findOne({ _id: postId, uid });
    if (!post) {
      return res.status(404).json({ success: false });
    }

    // ⏱️ 10-minute edit window
    const diff =
      (Date.now() - new Date(post.createdAt).getTime()) / 60000;

    if (diff > 10) {
      return res.status(403).json({
        success: false,
        message: "Edit window expired",
      });
    }

    post.text = text;
    post.edited = true;
    await post.save();

    res.json({
      success: true,
      post,
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Add comment to post
// @route   POST /api/posts/:id/comments
// @access  Private
export const addComment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { text, parentCommentId } = req.body;
    const userId = req.user._id;

    if (!text || text.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Comment text is required'
      });
    }

    const post = await Post.findById(id);

    if (!post || post.isDeleted) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Create comment
    const comment = await Comment.create({
      uid: userId,
      post: post._id,
      parentComment: parentCommentId || null,
      text: text.trim()
    });

    // Update post comments count
    post.commentsCount += 1;
    await post.save();

    // Create notification for post owner
    if (post.uid.toString() !== userId.toString()) {
  await createNotification({
    userId: post.uid,
    actorId: userId,
    type: parentCommentId ? "reply" : "comment",
    entityId: post._id,
    entityType: "post",
  });
}

    // If it's a reply, update parent comment replies count
    if (parentCommentId) {
      await Comment.findByIdAndUpdate(parentCommentId, {
        $inc: { repliesCount: 1 }
      });
    }

    // Populate user info
    await comment.populate('uid', 'uid username name avatar verified');

    res.status(201).json({
      success: true,
      message: 'Comment added successfully',
      comment: {
        id: comment._id,
        uid: comment.uid,
        text: comment.text,
        likesCount: comment.likesCount,
        repliesCount: comment.repliesCount,
        createdAt: comment.createdAt
      },
      commentsCount: post.commentsCount
    });
  } catch (error) {
    next(error);
  }
};
