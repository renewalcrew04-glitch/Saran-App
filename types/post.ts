import { Timestamp } from "firebase/firestore";

export type PostType = "text" | "photo" | "video" | "repost" | "quote";

export type Post = {
  id: string;
  uid: string;

  // author info (injected)
  username?: string;

  // type of the post itself
  type: PostType;

  text?: string;
  media?: string[];
  thumbnail?: string;

  createdAt: Timestamp;

  // ✅ Quote repost support
  isQuote?: boolean;
  originalPostId?: string;

  // ✅ Repost feed support (who reposted it)
  repostedByUid?: string;
  repostedByName?: string;

  // optional counts (if your post doc has it)
  likesCount?: number;
  commentsCount?: number;
  repostsCount?: number;
  sharesCount?: number;

  // optional
  visibility?: "public" | "private";
  isDeleted?: boolean;
  category?: string;
  hashtags?: string;
};
