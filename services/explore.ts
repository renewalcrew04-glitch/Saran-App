import {
  collection,
  getDocs,
  limit,
  orderBy,
  query,
  where,
  startAfter,
  QueryDocumentSnapshot,
} from "firebase/firestore";
import { db, auth } from "@/services/firebase";
import type { Post } from "@/types/post";
import { fetchPeople } from "./searchPeople";
import {
  getCachedPeople,
  setCachedPeople,
} from "./peopleRankingCache";

/* 🔹 POSTS */

export async function fetchExplorePostsPaginated({
  type,
  cursor,
  pageSize = 18,
}: {
  type?: "text" | "photo" | "video";
  cursor?: QueryDocumentSnapshot;
  pageSize?: number;
}) {
  if (!auth.currentUser) {
    return { posts: [], cursor: undefined };
  }

  const q = query(
    collection(db, "posts"),
    ...(type ? [where("type", "==", type)] : []),
    orderBy("createdAt", "desc"),
    ...(cursor ? [startAfter(cursor)] : []),
    limit(pageSize)
  );

  const snap = await getDocs(q);

  return {
    posts: snap.docs.map((d) => ({
      id: d.id,
      ...(d.data() as Omit<Post, "id">),
    })),
    cursor: snap.docs.at(-1),
  };
}

/* 🔹 PEOPLE (cached + ranked) */

export async function fetchExplorePeople(limitCount = 3) {
  const uid = auth.currentUser?.uid;
  if (!uid) return [];

  const cacheKey = `explore:${uid}:${limitCount}`;
  const cached = getCachedPeople(cacheKey);
  if (cached) return cached;

  const people = await fetchPeople(uid, limitCount * 3);

  const followersSnap = await getDocs(
    collection(db, "follows", uid, "followers")
  );
  const followers = new Set(followersSnap.docs.map(d => d.id));

  const followingSnap = await getDocs(
    collection(db, "follows", uid, "following")
  );
  const following = new Set(followingSnap.docs.map(d => d.id));

  const ranked = people.map(p => {
    const followsYou = followers.has(p.uid);
    const mutual = followsYou && following.has(p.uid);

    return {
      ...p,
      followsYou,
      mutualCount: Math.floor(Math.random() * 5), // placeholder
      _score:
        (followsYou ? 1000 : 0) +
        (mutual ? 500 : 0),
    };
  });

  const final = ranked
    .sort((a, b) => b._score - a._score)
    .slice(0, limitCount);

  setCachedPeople(cacheKey, final);
  return final;
}
