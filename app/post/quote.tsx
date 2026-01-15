import { View, Text, StyleSheet, TextInput, TouchableOpacity, ActivityIndicator } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useEffect, useState } from "react";
import { doc, getDoc, addDoc, collection, serverTimestamp } from "firebase/firestore";
import { auth, db } from "@/services/firebase";
import { Post } from "@/types/post";
import MediaPostCard from "@/components/MediaPostCard";
import PostCard from "@/components/PostCard";

export default function QuotePostScreen() {
  const router = useRouter();
  const { postId } = useLocalSearchParams<{ postId: string }>();

  const [loading, setLoading] = useState(true);
  const [originalPost, setOriginalPost] = useState<Post | null>(null);
  const [text, setText] = useState("");

  useEffect(() => {
    const load = async () => {
      try {
        if (!postId) return;
        const snap = await getDoc(doc(db, "posts", postId));
        if (snap.exists()) {
          setOriginalPost({ id: snap.id, ...(snap.data() as any) });
        }
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [postId]);

  const onPost = async () => {
    const uid = auth.currentUser?.uid;
    if (!uid || !originalPost) return;

    const trimmed = text.trim();
    if (!trimmed) return;

    const newRef = await addDoc(collection(db, "posts"), {
  uid,
  text: trimmed,
  createdAt: serverTimestamp(),
  quotePostId: originalPost.id,
  type: "quote",
});

// ✅ add timeline item for quote
const { addTimelineItem } = await import("@/services/timeline");
await addTimelineItem({ type: "quote", postId: newRef.id });

    router.back();
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator />
      </View>
    );
  }

  if (!originalPost) {
    return (
      <View style={styles.center}>
        <Text>Post not found</Text>
      </View>
    );
  }

  const isMedia = originalPost.media?.length;

  return (
    <View style={styles.root}>
      {/* Header */}
      <View style={styles.topBar}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.cancel}>Cancel</Text>
        </TouchableOpacity>

        <TouchableOpacity onPress={onPost} style={styles.postBtn}>
          <Text style={styles.postText}>Post</Text>
        </TouchableOpacity>
      </View>

      {/* Input */}
      <TextInput
        placeholder="Add a comment"
        placeholderTextColor="#999"
        value={text}
        onChangeText={setText}
        style={styles.input}
        multiline
      />

      {/* Original Post Preview */}
      <View style={styles.preview}>
        {isMedia ? (
          <MediaPostCard post={originalPost} context="home" hideActions />
        ) : (
          <PostCard post={originalPost} />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#fff",
    paddingTop: 40,
    paddingHorizontal: 14,
  },
  topBar: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
  },
  cancel: {
    fontSize: 16,
    color: "#111",
  },
  postBtn: {
    backgroundColor: "#000",
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 18,
  },
  postText: {
    color: "#fff",
    fontWeight: "700",
  },
  input: {
    fontSize: 16,
    minHeight: 80,
    textAlignVertical: "top",
    marginBottom: 10,
  },
  preview: {
    marginTop: 8,
  },
  center: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});
