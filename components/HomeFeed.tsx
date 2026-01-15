import { View, Text, FlatList } from "react-native";
import { useEffect, useMemo, useState } from "react";
import { auth } from "@/services/firebase";
import {
  collection,
  orderBy,
  query,
  where,
  limit,
  startAfter,
  getDocs,
  QueryDocumentSnapshot,
  DocumentData,
} from "firebase/firestore";
import QuotePostCard from "@/components/QuotePostCard";
import RepostWrapper from "@/components/RepostWrapper";
import { db } from "@/services/firebase";
import { getProfileLite } from "@/services/profileLookup";
import { Post } from "@/types/post";
import PostCard from "@/components/PostCard";
import MediaPostCard from "@/components/MediaPostCard";
import SFrameRow from "@/components/SFrameRow";
import DailyQuoteCard from "@/components/DailyQuoteCard";
import CategoryChips from "@/components/CategoryChips";
import ShareStoryCard from "@/components/ShareStoryCard";

const PAGE_SIZE = 10;

export default function HomeFeed() {
  const [posts, setPosts] = useState<any[]>([]);
  const [lastDoc, setLastDoc] =
    useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);

  // ✅ follow graph (for boosts)
  const [followingSet, setFollowingSet] = useState<Set<string>>(new Set());
  const [followersSet, setFollowersSet] = useState<Set<string>>(new Set());

  // ✅ Load following + followers once
  useEffect(() => {
    const loadFollowGraph = async () => {
      try {
        const myUid = auth.currentUser?.uid;
        if (!myUid) return;

        const followingSnap = await getDocs(
          collection(db, "follows", myUid, "following")
        );

        const followersSnap = await getDocs(
          collection(db, "follows", myUid, "followers")
        );

        setFollowingSet(new Set(followingSnap.docs.map((d) => d.id)));
        setFollowersSet(new Set(followersSnap.docs.map((d) => d.id)));
      } catch (e) {
        console.log("HomeFeed follow graph error:", e);
      }
    };

    loadFollowGraph();
  }, []);

  // ✅ Ranking function (recency + interactions + follow boosts)
  function rankTimelineItems(items: any[]) {
    const now = Date.now();

    function toMillis(ts: any) {
      if (!ts) return null;
      if (typeof ts === "number") return ts;
      if (ts?.toMillis) return ts.toMillis();
      if (ts?.seconds) return ts.seconds * 1000;
      return null;
    }

    function getScore(item: any) {
      // 🔥 Base recency score
      const createdAtMs = toMillis(item.createdAt) || now;
      const ageMinutes = Math.max(1, (now - createdAtMs) / 60000);

      // More recent => higher
      let score = 1000 / ageMinutes;

      // 🔥 Interaction score (from post document)
      const likes = item.likesCount || 0;
      const comments = item.commentsCount || 0;
      const reposts = item.repostsCount || 0;
      const shares = item.sharesCount || 0;

      score += likes * 2;
      score += comments * 3;
      score += reposts * 4;
      score += shares * 2;

      // ======================================================
      // ✅ FOLLOW BOOSTS (REPOST ITEMS)
      // ======================================================
      if (item.type === "repost") {
        const actorUid = item.repostedByUid;

        // ✅ people you follow boost
        if (actorUid && followingSet.has(actorUid)) {
          score += 500;
        }

        // ✅ mutual friend repost boost (both follow each other)
        if (
          actorUid &&
          followingSet.has(actorUid) &&
          followersSet.has(actorUid)
        ) {
          score += 900;
        }
      }

      return score;
    }

    return [...items].sort((a, b) => getScore(b) - getScore(a));
  }

  async function loadMore() {
    if (loading || done) return;

    setLoading(true);

    const baseQuery = query(
      collection(db, "posts"),
      where("visibility", "==", "public"),
      orderBy("createdAt", "desc"),
      limit(PAGE_SIZE)
    );

    const pagedQuery = lastDoc
      ? query(
          collection(db, "posts"),
          where("visibility", "==", "public"),
          orderBy("createdAt", "desc"),
          startAfter(lastDoc),
          limit(PAGE_SIZE)
        )
      : baseQuery;

    const snap = await getDocs(pagedQuery);

    if (snap.docs.length === 0) {
      setDone(true);
      setLoading(false);
      return;
    }

    const basePosts: any[] = snap.docs.map((docSnap) => ({
      id: docSnap.id,
      ...(docSnap.data() as Omit<Post, "id">),
    }));

    // 🔁 inject reposts
    const reposts: any[] = [];

    for (const post of basePosts) {
      try {
        const repostSnap = await getDocs(
          collection(db, "posts", post.id, "reposts")
        );

        repostSnap.docs.forEach((d) => {
          const data = d.data() as any;

          const actorUid = data?.uid || d.id;

          reposts.push({
            ...post,
            type: "repost",
            repostedByUid: actorUid,
            repostedAt: data?.createdAt || null,
          });
        });
      } catch (e) {
        // ignore repost injection errors
      }
    }

    const combined = [...reposts, ...basePosts];

    // 👤 fetch profiles for post author + repost actor
    const uniqueUids = [
      ...new Set([
        ...basePosts.map((p) => p.uid),
        ...reposts.map((p) => p.repostedByUid).filter(Boolean),
      ]),
    ];

    const profiles = await Promise.all(
      uniqueUids.map((uid) => getProfileLite(uid))
    );

    const profileMap = new Map<string, any>();
    profiles.forEach((p, index) => {
      if (p) profileMap.set(uniqueUids[index], p);
    });

    setPosts((prev) => {
      const map = new Map<string, any>();

      [...prev, ...combined].forEach((post: any) => {
        const key =
          post.type === "repost"
            ? `repost-${post.id}-${post.repostedByUid || post.uid}`
            : post.id;

        map.set(key, {
          ...post,

          // ✅ FIX: never override username to undefined
          username:
            profileMap.get(post.uid)?.name || post.username || "User",

          repostedByName:
            post.type === "repost"
              ? profileMap.get(post.repostedByUid)?.name || "User"
              : undefined,
        });
      });

      const merged = Array.from(map.values());

      // ✅ rank after merge
      return rankTimelineItems(merged);
    });

    setLastDoc(snap.docs[snap.docs.length - 1]);
    setLoading(false);
  }

  useEffect(() => {
    loadMore();
  }, []);

  // ✅ IMPORTANT: Re-rank again when follow graph loads
  useEffect(() => {
    setPosts((prev) => rankTimelineItems(prev));
  }, [followingSet, followersSet]);

  return (
    <FlatList
      data={posts}
      keyExtractor={(item: any) =>
        item.type === "repost"
          ? `repost-${item.id}-${item.repostedByUid || item.uid}`
          : item.id
      }
      onEndReached={loadMore}
      onEndReachedThreshold={0.6}
      showsVerticalScrollIndicator={false}
      ListHeaderComponent={
        <>
          <SFrameRow />
          <DailyQuoteCard />
          <CategoryChips />
          <ShareStoryCard />
        </>
      }
      renderItem={({ item }: any) => {
        // 🔁 Repost item UI (X style)
        if (item.type === "repost") {
          return <RepostWrapper post={item} />;
        }

        // ✍️ Quote post UI (X style)
        if (item.isQuote && item.originalPostId) {
          return <QuotePostCard post={item} />;
        }

        // Normal post
        return item.type === "text" ? (
          <PostCard post={item} />
        ) : (
          <MediaPostCard post={item} />
        );
      }}
      ListFooterComponent={
        loading ? (
          <Text style={{ padding: 16 }}>Loading…</Text>
        ) : done ? (
          <Text
            style={{
              padding: 16,
              color: "#999",
              textAlign: "center",
            }}
          >
            You’re all caught up 🌸
          </Text>
        ) : null
      }
    />
  );
}
