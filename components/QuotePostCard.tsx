import { View, Text, StyleSheet, Image, TouchableOpacity } from "react-native";
import { Post } from "@/types/post";
import { Colors } from "@constants/colors";
import { Spacing } from "@constants/spacing";
import { Typography } from "@constants/typography";
import PostActionsUI from "@/components/feed/PostActions";
import { useEffect, useState } from "react";
import { doc, getDoc } from "firebase/firestore";
import { db, auth } from "@/services/firebase";
import { formatPostTime } from "@/utils/formatPostTime";
import { FontAwesome6 } from "@expo/vector-icons";
import { useRouter } from "expo-router";

type Props = {
  post: Post; // quote post itself
};

export default function QuotePostCard({ post }: Props) {
  const router = useRouter();

  const [original, setOriginal] = useState<Post | null>(null);

  const [author, setAuthor] = useState<{
    name?: string;
    username?: string;
    avatar?: string;
  } | null>(null);

  const [originalAuthor, setOriginalAuthor] = useState<{
    name?: string;
    username?: string;
    avatar?: string;
  } | null>(null);

  useEffect(() => {
    const loadQuoteAuthor = async () => {
      try {
        const snap = await getDoc(doc(db, "profiles", post.uid));
        if (snap.exists()) setAuthor(snap.data());
      } catch {}
    };
    loadQuoteAuthor();
  }, [post.uid]);

  useEffect(() => {
    const loadOriginal = async () => {
      try {
        if (!post.originalPostId) return;

        const snap = await getDoc(doc(db, "posts", post.originalPostId));
        if (snap.exists()) {
          const data = snap.data() as any;

          const originalPost: Post = {
            id: snap.id,
            ...data,
          };

          setOriginal(originalPost);

          // load original author
          if (originalPost.uid) {
            const userSnap = await getDoc(doc(db, "profiles", originalPost.uid));
            if (userSnap.exists()) setOriginalAuthor(userSnap.data());
          }
        }
      } catch {}
    };

    loadOriginal();
  }, [post.originalPostId]);

  const isMyQuotePost = post.uid === auth.currentUser?.uid;

  return (
    <View style={styles.card}>
      {/* HEADER */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => router.push(`/profile/${post.uid}`)}
          activeOpacity={0.8}
        >
          {author?.avatar ? (
            <Image source={{ uri: author.avatar }} style={styles.avatar} />
          ) : (
            <View style={[styles.avatar, { backgroundColor: Colors.gray300 }]} />
          )}
        </TouchableOpacity>

        <View style={{ flex: 1 }}>
          <TouchableOpacity
            onPress={() => router.push(`/profile/${post.uid}`)}
            activeOpacity={0.8}
          >
            <View style={styles.nameRow}>
              <Text style={styles.name}>{author?.name || "User"}</Text>
              {!!author?.username && (
                <Text style={styles.username}>@{author.username}</Text>
              )}
              <Text style={styles.dot}>•</Text>
              <Text style={styles.timeInline}>
                {post.createdAt ? formatPostTime(post.createdAt) : ""}
              </Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* 3 DOT */}
        <TouchableOpacity
          onPress={() => {
            // you can reuse same menu logic like PostCard
            // keeping minimal here
          }}
          style={styles.menuBtn}
        >
          <FontAwesome6 name="ellipsis-vertical" size={16} color={Colors.black} />
        </TouchableOpacity>
      </View>

      {/* QUOTE TEXT */}
      {!!post.text && <Text style={styles.quoteText}>{post.text}</Text>}

      {/* ORIGINAL POST PREVIEW (X STYLE CARD) */}
      {!!original && (
        <TouchableOpacity
          activeOpacity={0.9}
          onPress={() =>
            router.push({
              pathname: "/post/[id]",
              params: { id: original.id },
            })
          }
          style={styles.previewCard}
        >
          {/* Original header */}
          <View style={styles.previewHeader}>
            {originalAuthor?.avatar ? (
              <Image source={{ uri: originalAuthor.avatar }} style={styles.previewAvatar} />
            ) : (
              <View
                style={[
                  styles.previewAvatar,
                  { backgroundColor: Colors.gray300 },
                ]}
              />
            )}

            <View style={{ flex: 1 }}>
              <View style={styles.previewNameRow}>
                <Text style={styles.previewName}>
                  {originalAuthor?.name || "User"}
                </Text>

                {!!originalAuthor?.username && (
                  <Text style={styles.previewUsername}>
                    @{originalAuthor.username}
                  </Text>
                )}
              </View>
            </View>
          </View>

          {/* Original text */}
          {!!original.text && (
            <Text style={styles.previewText} numberOfLines={4}>
              {original.text}
            </Text>
          )}

          {/* Original media preview (simple) */}
          {!!original.media?.length && (
            <View style={styles.mediaBox}>
              <Text style={{ color: "#777", fontSize: 12 }}>
                📷 Media attached
              </Text>
            </View>
          )}
        </TouchableOpacity>
      )}

      {/* ACTIONS (for quote post only) */}
      <PostActionsUI postId={post.id} postOwnerId={post.uid} />
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: Spacing.md,
    marginTop: Spacing.lg,
    padding: Spacing.md,
    borderRadius: 18,
    backgroundColor: Colors.white,
    shadowColor: "#000",
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
    elevation: 3,
  },

  header: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 8,
  },

  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    marginRight: 10,
  },

  nameRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    flexWrap: "wrap",
  },

  name: {
    fontSize: 14,
    fontWeight: "700",
    color: Colors.black,
  },

  username: {
    fontSize: 12,
    color: Colors.gray700,
  },

  dot: {
    fontSize: 12,
    color: Colors.gray500,
  },

  timeInline: {
    fontSize: 12,
    color: Colors.gray700,
  },

  menuBtn: {
    padding: 6,
    marginLeft: 6,
  },

  quoteText: {
    ...Typography.body,
    color: Colors.black,
    lineHeight: 20,
    marginBottom: 10,
  },

  previewCard: {
    borderWidth: 1,
    borderColor: "#eee",
    borderRadius: 14,
    padding: 12,
    marginBottom: 8,
    backgroundColor: "#fff",
  },

  previewHeader: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 6,
  },

  previewAvatar: {
    width: 26,
    height: 26,
    borderRadius: 13,
    marginRight: 8,
  },

  previewNameRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    flexWrap: "wrap",
  },

  previewName: {
    fontSize: 13,
    fontWeight: "700",
    color: Colors.black,
  },

  previewUsername: {
    fontSize: 12,
    color: Colors.gray700,
  },

  previewText: {
    fontSize: 13,
    color: Colors.black,
    lineHeight: 18,
  },

  mediaBox: {
    marginTop: 10,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#eee",
    padding: 10,
    alignItems: "center",
  },
});
