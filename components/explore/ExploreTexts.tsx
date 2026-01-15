import { FlatList } from "react-native";
import { useEffect, useState } from "react";
import { collection, query, where, orderBy, limit, getDocs } from "firebase/firestore";
import { db } from "@/services/firebase";
import { Post } from "@/types/post";
import PostCard from "@/components/PostCard";

export default function ExploreTexts() {
  const [posts, setPosts] = useState<Post[]>([]);

  useEffect(() => {
    async function load() {
      const q = query(
        collection(db, "posts"),
        where("type", "==", "text"),
        orderBy("createdAt", "desc"),
        limit(30)
      );

      const snap = await getDocs(q);
      setPosts(
        snap.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Omit<Post, "id">),
        }))
      );
    }
    load();
  }, []);

  return (
    <FlatList
      data={posts}
      numColumns={3}
      keyExtractor={(p) => p.id}
      renderItem={({ item }) => (
        <PostCard post={item} />
      )}
    />
  );
}
