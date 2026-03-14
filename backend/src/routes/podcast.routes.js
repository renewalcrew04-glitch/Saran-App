import express from "express";
import * as controller from "../controllers/podcast.controller.js";

const router = express.Router();

/* Podcasts */

router.post("/podcasts", controller.createPodcast);

router.get("/podcasts", controller.getPodcasts);

router.get("/podcasts/:id", controller.getPodcast);

router.post("/podcasts/:id/follow", controller.followPodcast);

/* Episodes */

router.post("/podcasts/:id/episodes", controller.createEpisode);

router.get("/podcasts/:id/episodes", controller.getEpisodes);

router.get("/episodes/:id", controller.getEpisode);

router.post("/episodes/:id/listen", controller.listenEpisode);

export default router;