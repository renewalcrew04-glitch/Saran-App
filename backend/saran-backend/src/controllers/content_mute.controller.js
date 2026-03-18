import ContentMute from "../models/ContentMute.model.js";

// Get mute settings
export const getMutedContent = async (req, res, next) => {
  try {
    const uid = req.user._id;

    let mute = await ContentMute.findOne({ uid });

    if (!mute) {
      mute = await ContentMute.create({
        uid,
        mutedWords: [],
        mutedHashtags: [],
      });
    }

    res.json({
      success: true,
      mutedWords: mute.mutedWords,
      mutedHashtags: mute.mutedHashtags,
    });
  } catch (err) {
    next(err);
  }
};

// Update mute settings
export const updateMutedContent = async (req, res, next) => {
  try {
    const uid = req.user._id;
    const { mutedWords, mutedHashtags } = req.body;

    const mute = await ContentMute.findOneAndUpdate(
      { uid },
      {
        mutedWords: mutedWords ?? [],
        mutedHashtags: mutedHashtags ?? [],
      },
      { new: true, upsert: true }
    );

    res.json({
      success: true,
      mutedWords: mute.mutedWords,
      mutedHashtags: mute.mutedHashtags,
    });
  } catch (err) {
    next(err);
  }
};
