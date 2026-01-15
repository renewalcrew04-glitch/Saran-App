import { Timestamp } from "firebase/firestore";
import type { Post } from "@/types/post";

/* =========================================================
   FEED RANKING (HOME FEED)
   - Recency
   - Mutual friend repost boost
   - Following repost boost
   - Interaction boost (likes/comments/reposts/shares)
========================================================= */

type FeedSignals = {
  likes?: number;
  comments?: number;
  reposts?: number;
  shares?: number;
  // whether current user follows the post author
  isFollowingAuthor?: boolean;
  // whether author is mutual friend (both follow each other)
  isMutualFriend?: boolean;

  // whether this post is reposted by a mutual friend / following user
  repostedByMutualFriend?: boolean;
  repostedByFollowing?: boolean;
};

function toMillis(createdAt: any): number {
  if (!createdAt) return Date.now();

  // Firestore Timestamp
  if (createdAt instanceof Timestamp) return createdAt.toMillis();

  // serverTimestamp sometimes comes as { seconds, nanoseconds }
  if (typeof createdAt?.seconds === "number") {
    return createdAt.seconds * 1000;
  }

  // JS Date
  if (createdAt instanceof Date) return createdAt.getTime();

  // number already
  if (typeof createdAt === "number") return createdAt;

  return Date.now();
}

function clamp(n: number, min: number, max: number) {
  return Math.max(min, Math.min(max, n));
}

/**
 * Score posts for HOME FEED ranking.
 * Higher score = higher in feed.
 */
export function scorePost(
  post: Post,
  signals: FeedSignals = {}
): number {
  const now = Date.now();
  const createdMs = toMillis((post as any).createdAt);
  const ageHours = (now - createdMs) / (1000 * 60 * 60);

  // ------------------------------
  // 1) Recency score (0 → 100)
  // Fresh posts get more weight
  // ------------------------------
  const recencyScore = clamp(100 - ageHours * 4, 0, 100);

  // ------------------------------
  // 2) Interaction score
  // (log-ish via sqrt so huge posts don't dominate)
  // ------------------------------
  const likes = signals.likes ?? 0;
  const comments = signals.comments ?? 0;
  const reposts = signals.reposts ?? 0;
  const shares = signals.shares ?? 0;

  const interactionScore =
    Math.sqrt(likes) * 6 +
    Math.sqrt(comments) * 10 +
    Math.sqrt(reposts) * 12 +
    Math.sqrt(shares) * 8;

  // ------------------------------
  // 3) Social relationship boost
  // ------------------------------
  let socialBoost = 0;

  if (signals.isMutualFriend) socialBoost += 40;
  else if (signals.isFollowingAuthor) socialBoost += 20;

  // Repost boosts (if timeline later supports it)
  if (signals.repostedByMutualFriend) socialBoost += 35;
  else if (signals.repostedByFollowing) socialBoost += 15;

  // ------------------------------
  // 4) Final score
  // Recency is the main driver
  // ------------------------------
  const score =
    recencyScore * 1.4 +
    interactionScore * 1.0 +
    socialBoost * 1.0;

  return score;
}

/**
 * Sort posts using scorePost().
 * You can pass a callback to provide signals for each post.
 */
export function rankPosts(
  posts: Post[],
  getSignals?: (post: Post) => FeedSignals
): Post[] {
  return [...posts].sort((a, b) => {
    const sa = scorePost(a, getSignals ? getSignals(a) : {});
    const sb = scorePost(b, getSignals ? getSignals(b) : {});
    return sb - sa;
  });
}
