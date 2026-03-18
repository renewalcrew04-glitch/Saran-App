import Podcast from "../models/podcast.model.js";
import PodcastEpisode from "../models/podcast_episode.model.js";

export async function createPodcast(data) {
  return Podcast.create(data);
}

export async function getAllPodcasts() {
  return Podcast.find({ isActive: true }).sort({ createdAt: -1 });
}

export async function getPodcastById(id) {
  return Podcast.findById(id);
}

/** Update podcast title/description. Only allowed if userId matches creatorId. */
export async function updatePodcast(id, userId, data) {
  const podcast = await Podcast.findById(id);
  if (!podcast) return null;
  if (podcast.creatorId?.toString() !== userId?.toString()) {
    const err = new Error("Not authorized to update this podcast");
    err.statusCode = 403;
    throw err;
  }
  if (data.title != null) podcast.title = data.title;
  if (data.description != null) podcast.description = data.description;
  if (data.category != null) podcast.category = data.category;
  if (data.coverUrl != null) podcast.coverUrl = data.coverUrl;
  await podcast.save();
  return podcast;
}

/** Delete podcast and its episodes. Only allowed if userId matches creatorId. */
export async function deletePodcast(id, userId) {
  const podcast = await Podcast.findById(id);
  if (!podcast) return null;
  if (podcast.creatorId?.toString() !== userId?.toString()) {
    const err = new Error("Not authorized to delete this podcast");
    err.statusCode = 403;
    throw err;
  }
  await PodcastEpisode.deleteMany({ podcastId: id });
  await Podcast.findByIdAndDelete(id);
  return { deleted: true };
}

export async function followPodcast(podcastId, userId) {
  return Podcast.findByIdAndUpdate(
    podcastId,
    { $addToSet: { followers: userId } },
    { new: true }
  );
}

export async function createEpisode(data) {
  const episode = await PodcastEpisode.create(data);

  await Podcast.findByIdAndUpdate(data.podcastId, {
    $inc: { totalEpisodes: 1 },
  });

  return episode;
}

export async function getEpisodes(podcastId) {
  return PodcastEpisode.find({ podcastId }).sort({ createdAt: -1 });
}

export async function getEpisodeById(id) {
  return PodcastEpisode.findById(id);
}

export async function increaseListen(episodeId) {
  return PodcastEpisode.findByIdAndUpdate(
    episodeId,
    { $inc: { listens: 1 } },
    { new: true }
  );
}