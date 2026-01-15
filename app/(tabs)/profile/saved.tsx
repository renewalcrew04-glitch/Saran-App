import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Image,
  TouchableOpacity,
} from "react-native";
import { useEffect, useState } from "react";
import { collection, getDocs, doc, getDoc } from "firebase/firestore";
import { Ionicons } from "@expo/vector-icons";

import { db, auth } from "@/services/firebase";

type Post = {
  id: string;
  type: "text" | "photo" | "video" | "repost";
  text?: string;
  mediaUrls?: string[];
};

export default function SavedScreen() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSavedPosts();
  }, []);

  const loadSavedPosts = async () => {
    const uid = auth.currentUser?.uid;
    if (!uid) return;

    setLoading(true);

    const savedRef = collection(db, "profiles", uid, "saved");
    const savedSnap = await getDocs(savedRef);

    const results: Post[] = [];

    for (const savedDoc of savedSnap.docs) {
      const postId = savedDoc.id;
      const postRef = doc(db, "posts", postId);
      const postSnap = await getDoc(postRef);

      if (postSnap.exists()) {
        results.push({
  ...(postSnap.data() as Post),
  id: postSnap.id,
});
      }
    }

    setPosts(results);
    setLoading(false);
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <Text>Loading saved posts…</Text>
      </View>
    );
  }

  if (posts.length === 0) {
    return (
      <View style={styles.center}>
        <Ionicons name="bookmark-outline" size={36} color="#aaa" />
        <Text style={styles.emptyText}>
          No saved posts yet
        </Text>
      </View>
    );
  }

  return (
    <FlatList
      data={posts}
      numColumns={3}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => (
        <View style={styles.item}>
          {item.type === "text" ? (
            <View style={styles.textPost}>
              <Text numberOfLines={4} style={styles.text}>
                {item.text}
              </Text>
            </View>
          ) : (
            <>
              <Image
                source={{ uri: item.mediaUrls?.[0] }}
                style={styles.image}
              />
              {item.type === "video" && (
                <View style={styles.play}>
                  <Ionicons name="play" size={18} color="#fff" />
                </View>
              )}
            </>
          )}
        </View>
      )}
    />
  );
}

const SIZE = 130;

const styles = StyleSheet.create({
  center: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },

  emptyText: {
    marginTop: 8,
    color: "#777",
  },

  item: {
    width: SIZE,
    height: SIZE,
    borderWidth: 0.5,
    borderColor: "#eee",
  },

  image: {
    width: "100%",
    height: "100%",
  },

  play: {
    position: "absolute",
    top: "45%",
    left: "45%",
    backgroundColor: "rgba(0,0,0,0.6)",
    borderRadius: 20,
    padding: 6,
  },

  textPost: {
    flex: 1,
    backgroundColor: "#f2f2f2",
    alignItems: "center",
    justifyContent: "center",
    padding: 8,
  },

  text: {
    fontSize: 13,
    color: "#333",
    textAlign: "center",
  },
});
