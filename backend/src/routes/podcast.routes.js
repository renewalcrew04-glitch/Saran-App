import express from "express";
import { protect } from "../middleware/auth.middleware.js";
import * as controller from "../controllers/podcast.controller.js";

const router = express.Router();

/* Podcasts */

router.post("/podcasts", protect, controller.createPodcast);

router.get("/podcasts", controller.getPodcasts);

router.get("/podcasts/:id", controller.getPodcast);

router.put("/podcasts/:id", protect, controller.updatePodcast);

router.delete("/podcasts/:id", protect, controller.deletePodcast);

router.post("/podcasts/:id/follow", controller.followPodcast);

/* Episodes */

router.post("/podcasts/:id/episodes", controller.createEpisode);

router.get("/podcasts/:id/episodes", controller.getEpisodes);

router.get("/episodes/:id", controller.getEpisode);

router.post("/episodes/:id/listen", controller.listenEpisode);

export default router;