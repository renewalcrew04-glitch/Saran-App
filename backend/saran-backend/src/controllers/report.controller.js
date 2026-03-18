import Post from "../models/Post.model.js";
import Report from "../models/Report.model.js";
import User from "../models/User.model.js";

export const reportPost = async (req, res, next) => {
  try {
    const reporterId = req.user._id;
    const { postId } = req.params;
    const { reason } = req.body;

    if (!reason || reason.trim().length < 3) {
      return res.status(400).json({ success: false, message: "Reason required" });
    }

    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post not found" });
    }

    await Report.create({
      reporter: reporterId,
      type: "post",
      post: post._id,
      reason: reason.trim(),
    });

    return res.json({ success: true, message: "Post reported" });
  } catch (err) {
    next(err);
  }
};

export const reportUser = async (req, res, next) => {
  try {
    const reporterId = req.user._id;
    const { uid } = req.params;
    const { reason } = req.body;

    if (!reason || reason.trim().length < 3) {
      return res.status(400).json({ success: false, message: "Reason required" });
    }

    const user = await User.findOne({ uid });
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    await Report.create({
      reporter: reporterId,
      type: "user",
      reportedUser: user._id,
      reason: reason.trim(),
    });

    return res.json({ success: true, message: "User reported" });
  } catch (err) {
    next(err);
  }
};
