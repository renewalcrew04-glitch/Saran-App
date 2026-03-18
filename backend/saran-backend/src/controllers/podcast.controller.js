import * as service from "../services/podcast.service.js";

export async function createPodcast(req, res, next) {
  try {
    const body = { ...req.body };
    if (req.user?._id) body.creatorId = req.user._id;
    const podcast = await service.createPodcast(body);
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
    if (!podcast) {
      return res.status(404).json({ success: false, message: 'Podcast not found' });
    }
    res.json({ success: true, data: podcast });
  } catch (err) {
    next(err);
  }
}

export async function updatePodcast(req, res, next) {
  try {
    const podcast = await service.updatePodcast(req.params.id, req.user._id, req.body);
    if (!podcast) {
      return res.status(404).json({ success: false, message: "Podcast not found" });
    }
    res.json({ success: true, data: podcast });
  } catch (err) {
    if (err.statusCode === 403) {
      return res.status(403).json({ success: false, message: err.message });
    }
    next(err);
  }
}

export async function deletePodcast(req, res, next) {
  try {
    const podcast = await service.deletePodcast(req.params.id, req.user._id);
    if (!podcast) {
      return res.status(404).json({ success: false, message: "Podcast not found" });
    }
    res.json({ success: true, data: podcast });
  } catch (err) {
    if (err.statusCode === 403) {
      return res.status(403).json({ success: false, message: err.message });
    }
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