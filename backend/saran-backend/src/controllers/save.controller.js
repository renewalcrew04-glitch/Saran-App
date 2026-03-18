import SaveCollection from "../models/SaveCollection.model.js";

// Ensure default collection
const ensureDefaultCollection = async (uid) => {
  let collection = await SaveCollection.findOne({
    uid,
    name: "Saved",
  });

  if (!collection) {
    collection = await SaveCollection.create({
      uid,
      name: "Saved",
      posts: [],
    });
  }

  return collection;
};

// Save / Unsave post
export const toggleSavePost = async (req, res, next) => {
  try {
    const uid = req.user._id;
    const { postId } = req.params;

    await ensureDefaultCollection(uid);

    const collections = await SaveCollection.find({ uid });

    let isSaved = false;

    for (const col of collections) {
      if (col.posts.includes(postId)) {
        col.posts.pull(postId);
        await col.save();
        isSaved = true;
      }
    }

    if (!isSaved) {
      const saved = await SaveCollection.findOne({
        uid,
        name: "Saved",
      });
      saved.posts.push(postId);
      await saved.save();
    }

    res.json({
      success: true,
      saved: !isSaved,
    });
  } catch (err) {
    next(err);
  }
};

// Create new collection
export const createCollection = async (req, res, next) => {
  try {
    const uid = req.user._id;
    const { name } = req.body;

    if (!name || name.trim().length < 2) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid name" });
    }

    const collection = await SaveCollection.create({
      uid,
      name: name.trim(),
      posts: [],
    });

    res.json({ success: true, collection });
  } catch (err) {
    next(err);
  }
};

// Get user collections
export const getCollections = async (req, res, next) => {
  try {
    const uid = req.user._id;
    await ensureDefaultCollection(uid);

    const collections = await SaveCollection.find({ uid }).populate(
      "posts"
    );

    res.json({ success: true, collections });
  } catch (err) {
    next(err);
  }
};
