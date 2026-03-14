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