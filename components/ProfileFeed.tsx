import { View, Text } from "react-native";
import { useEffect, useState } from "react";
import { onSnapshot } from "firebase/firestore";
import {
  collection,
  getDocs,
  query,
  where,
  orderBy,
} from "firebase/firestore";

import { db } from "@/services/firebase";
import { Post } from "@/types/post";
import PostCard from "@/components/PostCard";
import MediaPostCard from "@/components/MediaPostCard";

type Props = {
  uid: string;
};

export default function ProfileFeed({ uid }: Props) {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
  if (!uid) return;

  const postsQuery = query(
    collection(db, "posts"),
    orderBy("createdAt", "desc")
  );

  return onSnapshot(postsQuery, async (snap) => {
    const allPosts = snap.docs.map((doc) => ({
      id: doc.id,
      ...(doc.data() as Omit<Post, "id">),
    }));

    // Own posts
    const ownPosts = allPosts.filter(
      (p) => p.uid === uid
    );

    // Reposted posts
    const reposted = [];

    for (const post of allPosts) {
      const repostRef = collection(
        db,
        "posts",
        post.id,
        "reposts"
      );

      const repostSnap = await getDocs(repostRef);
      if (repostSnap.docs.some((d) => d.id === uid)) {
        reposted.push({
          ...post,
          type: "repost" as const,
        });
      }
    }

    setPosts([...reposted, ...ownPosts]);
    setLoading(false);
  });
}, [uid]);

  if (loading) {
    return (
      <View style={{ padding: 24 }}>
        <Text>Loading posts…</Text>
      </View>
    );
  }

  if (posts.length === 0) {
    return (
      <View style={{ padding: 24 }}>
        <Text style={{ color: "#999" }}>
          No posts yet
        </Text>
      </View>
    );
  }

  return (
    <View>
      {posts.map((post) =>
        post.type === "text" ? (
          <PostCard key={post.id} post={post} />
        ) : (
          <MediaPostCard key={post.id} post={post} />
        )
      )}
    </View>
  );
}
