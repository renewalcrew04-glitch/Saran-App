import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Image,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useEffect, useState } from "react";
import {
  doc,
  getDoc,
  addDoc,
  collection,
  serverTimestamp,
} from "firebase/firestore";
import { auth, db } from "@/services/firebase";
import { Post } from "@/types/post";
import MediaPostCard from "@/components/MediaPostCard";
import PostCard from "@/components/PostCard";

export default function QuoteRepostCreateScreen() {
  const router = useRouter();
  const { postId } = useLocalSearchParams<{ postId: string }>();

  const [loading, setLoading] = useState(true);
  const [posting, setPosting] = useState(false);

  const [originalPost, setOriginalPost] = useState<Post | null>(null);
  const [text, setText] = useState("");

  const [me, setMe] = useState<{
    name?: string;
    username?: string;
    avatar?: string;
  } | null>(null);

  useEffect(() => {
    const load = async () => {
      try {
        if (!postId) return;

        // ✅ Load original post
        const snap = await getDoc(doc(db, "posts", postId));
        if (snap.exists()) {
          setOriginalPost({
            id: snap.id,
            ...(snap.data() as any),
          });
        }

        // ✅ Load my profile
        const uid = auth.currentUser?.uid;
        if (uid) {
          const meSnap = await getDoc(doc(db, "profiles", uid));
          if (meSnap.exists()) {
            setMe(meSnap.data() as any);
          }
        }
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [postId]);

  const onQuotePost = async () => {
    try {
      if (!originalPost) return;

      const uid = auth.currentUser?.uid;
      if (!uid) return;

      const trimmed = text.trim();
      if (!trimmed) return;

      setPosting(true);

      // ✅ Create a NEW post (quote post)
      await addDoc(collection(db, "posts"), {
        uid,
        text: trimmed,
        createdAt: serverTimestamp(),
        visibility: "public",

        // 🔥 Quote reference
        originalPostId: originalPost.id,
        type: "text",
        isQuote: true,
      });

      setPosting(false);
      router.back();
    } catch (e) {
      setPosting(false);
      console.log("Quote repost error:", e);
    }
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

  const isMedia = !!originalPost.media?.length;

  return (
    <SafeAreaView style={styles.root} edges={["top"]}>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : undefined}
      >
        {/* TOP BAR */}
        <View style={styles.topBar}>
          <TouchableOpacity onPress={() => router.back()}>
            <Text style={styles.cancel}>Cancel</Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={onQuotePost}
            disabled={posting || !text.trim()}
            style={[
              styles.postBtn,
              (!text.trim() || posting) && { opacity: 0.5 },
            ]}
          >
            <Text style={styles.postText}>
              {posting ? "Posting..." : "Post"}
            </Text>
          </TouchableOpacity>
        </View>

        {/* ✅ MY PROFILE ROW (X STYLE) */}
        <View style={styles.meRow}>
          {me?.avatar ? (
            <Image source={{ uri: me.avatar }} style={styles.avatarImg} />
          ) : (
            <View style={styles.avatarFallback} />
          )}

          <View style={{ flex: 1 }}>
            <View style={styles.meNameRow}>
              <Text style={styles.meName}>{me?.name || "You"}</Text>

              {!!me?.username && (
                <Text style={styles.meUsername}>@{me.username}</Text>
              )}
            </View>

            {/* INPUT */}
            <TextInput
              value={text}
              onChangeText={setText}
              placeholder="Add a comment"
              placeholderTextColor="#999"
              style={styles.input}
              multiline
            />
          </View>
        </View>

        {/* ORIGINAL POST PREVIEW */}
        <View style={styles.preview}>
          {isMedia ? (
  <MediaPostCard post={originalPost} context="home" hideActions />
) : (
  <PostCard post={originalPost} />
)}
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#fff",
  },

  topBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 14,
    paddingTop: 8,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderColor: "#eee",
  },

  cancel: {
    fontSize: 15,
    color: "#111",
    fontWeight: "600",
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

  meRow: {
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 14,
    paddingTop: 12,
  },

  avatarImg: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: "#ddd",
  },

  avatarFallback: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: "#ddd",
  },

  meNameRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginBottom: 4,
  },

  meName: {
    fontSize: 14,
    fontWeight: "700",
    color: "#111",
  },

  meUsername: {
    fontSize: 13,
    color: "#777",
    fontWeight: "500",
  },

  input: {
    fontSize: 16,
    minHeight: 70,
    textAlignVertical: "top",
    color: "#111",
    paddingRight: 10,
  },

  preview: {
    paddingHorizontal: 10,
    marginTop: 10,
  },

  center: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});
