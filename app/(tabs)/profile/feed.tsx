import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
} from "react-native";
import { fetchUserPosts } from "@/services/posts";
import { useProfileStore } from "@/store/profileStore";
import { Post } from "@/types/post";
import MediaPostCard from "@/components/MediaPostCard";
import { Ionicons } from "@expo/vector-icons";
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from "react";
import { useFocusEffect, useLocalSearchParams, useRouter } from "expo-router";
import { useNavigation } from "@react-navigation/native";


export default function ProfilePostFeed() {
  const router = useRouter();

  const { uid, postId } = useLocalSearchParams<{
    uid?: string;
    postId?: string;
  }>();

  const [posts, setPosts] = useState<Post[]>([]);
  const listRef = useRef<FlatList<Post>>(null);
  const navigation = useNavigation();

useLayoutEffect(() => {
  navigation.setOptions({
    headerShown: false,
  });
}, []);


  /* ===== PROFILE STORE (EXISTING) ===== */
  const name = useProfileStore((s) => s.name);
  const hydrate = useProfileStore((s) => s.hydrate);

  /* ===== LOAD DATA ===== */
  useEffect(() => {
  if (!uid) return;
  hydrate(uid);
}, [uid]);

/* ===== LOAD POSTS (REFRESH ON SCREEN FOCUS) ===== */

useFocusEffect(
  useCallback(() => {
    if (!uid) return;

    fetchUserPosts(uid).then(setPosts);
  }, [uid])
);


  /* ===== AUTO SCROLL TO SELECTED POST ===== */
  useEffect(() => {
    if (!postId || posts.length === 0) return;

    const index = posts.findIndex((p) => p.id === postId);
    if (index >= 0) {
      setTimeout(() => {
        listRef.current?.scrollToIndex({
          index,
          animated: false,
        });
      }, 300);
    }
  }, [postId, posts]);

  return (
    <View style={styles.root}>
      {/* ===== CUSTOM HEADER ===== */}
      {/* CUSTOM HEADER */}
<View style={styles.header}>
  <TouchableOpacity
    onPress={() => router.back()}
    style={styles.back}
  >
    <Ionicons
      name="arrow-back"
      size={22}
      color="#fff"
    />
  </TouchableOpacity>

  <View style={styles.headerCenter}>
    <Text style={styles.title}>Posts</Text>
    {!!name && (
      <Text style={styles.subtitle}>{name}</Text>
    )}
  </View>
</View>

      {/* ===== POSTS FEED ===== */}
      <FlatList
        ref={listRef}
        data={posts}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
  <MediaPostCard
    post={item}
    context="profile"
  />
)}
        getItemLayout={(_, index) => ({
          length: 520,
          offset: 520 * index,
          index,
        })}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
}

/* ================= STYLES ================= */

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#fff",
  },

  header: {
  height: 64,
  backgroundColor: "#000",
  flexDirection: "row",
  alignItems: "center",
  paddingHorizontal: 12,
},

back: {
  position: "absolute",
  left: 12,
  padding: 6,
},

headerCenter: {
  flex: 1,
  alignItems: "center",
},

title: {
  color: "#fff",
  fontSize: 16,
  fontWeight: "700",
},

subtitle: {
  color: "#aaa",
  fontSize: 12,
  marginTop: 2,
},

});
