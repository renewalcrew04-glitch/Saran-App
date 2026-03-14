import * as service from "../services/podcast.service.js";

export async function createPodcast(req, res, next) {
  try {
    const podcast = await service.createPodcast(req.body);
    res.json({ success: true, data: podcast });
  } catch (err) {
    next(err);
  }
}

export async function getPodcasts(req, res, next) {
  try {
    const podcasts = await service.getAllPodcasts();
    res.json({ success: true, data: podcasts });
  } catch (err) {
    next(err);
  }
}

export async function getPodcast(req, res, next) {
  try {
    const podcast = await service.getPodcastById(req.params.id);
    res.json({ success: true, data: podcast });
  } catch (err) {
    next(err);
  }
}

export async function followPodcast(req, res, next) {
  try {
    const podcast = await service.followPodcast(
      req.params.id,
      req.user.id
    );

    res.json({ success: true, data: podcast });
  } catch (err) {
    next(err);
  }
}

export async function createEpisode(req, res, next) {
  try {
    const episode = await service.createEpisode(req.body);
    res.json({ success: true, data: episode });
  } catch (err) {
    next(err);
  }
}

export async function getEpisodes(req, res, next) {
  try {
    const episodes = await service.getEpisodes(req.params.id);
    res.json({ success: true, data: episodes });
  } catch (err) {
    next(err);
  }
}

export async function getEpisode(req, res, next) {
  try {
    const episode = await service.getEpisodeById(req.params.id);
    res.json({ success: true, data: episode });
  } catch (err) {
    next(err);
  }
}

export async function listenEpisode(req, res, next) {
  try {
    const episode = await service.increaseListen(req.params.id);
    res.json({ success: true, data: episode });
  } catch (err) {
    next(err);
  }
}