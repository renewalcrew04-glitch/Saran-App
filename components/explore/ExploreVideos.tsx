import { FlatList, View } from "react-native";
import { useEffect, useState } from "react";
import { collection, query, where, orderBy, limit, getDocs } from "firebase/firestore";
import { Video, ResizeMode } from "expo-av";
import { db } from "@/services/firebase";
import { Post } from "@/types/post";

export default function ExploreVideos() {
  const [posts, setPosts] = useState<Post[]>([]);

  useEffect(() => {
    async function load() {
      const q = query(
        collection(db, "posts"),
        where("type", "==", "video"),
        orderBy("createdAt", "desc"),
        limit(20)
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
        <View style={{ width: "33.33%", aspectRatio: 9 / 16 }}>
          <Video
  source={{ uri: item.media?.[0] ?? "" }}
  style={{ width: "100%", height: "100%" }}
  resizeMode={ResizeMode.COVER}
  isMuted
  shouldPlay={false}
/>
        </View>
      )}
    />
  );
}
