import { View, Text, StyleSheet, TouchableOpacity, Image } from "react-native";
import { Colors } from "@constants/colors";
import { Spacing } from "@constants/spacing";
import { Typography } from "@constants/typography";
import { Post } from "@/types/post";
import { useRouter } from "expo-router";
import { formatPostTime } from "@/utils/formatPostTime";
import PostActionsUI from "@/components/feed/PostActions";
import { useEffect, useState } from "react";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/services/firebase";
import { Alert } from "react-native";
import { FontAwesome6 } from "@expo/vector-icons";
import { auth } from "@/services/firebase";
import { deleteDoc } from "firebase/firestore";


type Props = {
  post: Post;
  hideActions?: boolean;
};

export default function PostCard({ post, hideActions = false }: Props) {
  const router = useRouter();

  const [author, setAuthor] = useState<{
    name?: string;
    username?: string;
    avatar?: string;
  } | null>(null);

  // 🔄 refresh time label every minute
  const [, forceUpdate] = useState(0);
  useEffect(() => {
    const t = setInterval(() => {
      forceUpdate((n) => n + 1);
    }, 60000);
    return () => clearInterval(t);
  }, []);

  // 👤 load author from profiles collection
  useEffect(() => {
    const loadAuthor = async () => {
      try {
        const snap = await getDoc(doc(db, "profiles", post.uid));
        if (snap.exists()) {
          setAuthor(snap.data());
        }
      } catch {
        // ignore
      }
    };

    loadAuthor();
  }, [post.uid]);

  const isMyPost = post.uid === auth.currentUser?.uid;

const openMenu = () => {
  if (isMyPost) {
    Alert.alert("Post options", "", [
      {
        text: "Edit",
        onPress: () => router.push(`/post/edit/${post.id}`),
      },
      {
        text: "Delete",
        style: "destructive",
        onPress: async () => {
          await deleteDoc(doc(db, "posts", post.id));
        },
      },
      { text: "Cancel", style: "cancel" },
    ]);
  } else {
    Alert.alert("Post options", "", [
      {
        text: "Report",
        style: "destructive",
        onPress: () => router.push(`/post/report/${post.id}`),
      },
      { text: "Cancel", style: "cancel" },
    ]);
  }
};

  return (
    <View style={styles.card}>
      {/* HEADER */}
      <View style={styles.header}>
  {/* LEFT SIDE (avatar + name + username + time) */}
  <View style={styles.left}>
    {author?.avatar ? (
      <TouchableOpacity
        onPress={() => router.push(`/profile/${post.uid}`)}
        activeOpacity={0.8}
      >
        <Image source={{ uri: author.avatar }} style={styles.avatarImg} />
      </TouchableOpacity>
    ) : (
      <TouchableOpacity
        onPress={() => router.push(`/profile/${post.uid}`)}
        activeOpacity={0.8}
      >
        <View style={styles.avatar} />
      </TouchableOpacity>
    )}

{/* 🔁 REPOST LABEL INSIDE CARD */}
{!!(post as any).repostedByName && (
  <View style={styles.repostRow}>
    <FontAwesome6 name="repeat" size={12} color={Colors.gray700} />
    <Text style={styles.repostText}>
      {(post as any).repostedByName} reposted
    </Text>
  </View>
)}

    <View style={styles.userInfo}>
      <TouchableOpacity onPress={() => router.push(`/profile/${post.uid}`)}>
        <View style={styles.nameRow}>
          <Text style={styles.name}>
            {author?.name || post.username || "User"}
          </Text>

          <Text style={styles.dot}>•</Text>

          <Text style={styles.timeInline}>
            {post.createdAt ? formatPostTime(post.createdAt) : ""}
          </Text>
        </View>

        {!!author?.username && (
          <Text style={styles.username}>@{author.username}</Text>
        )}
      </TouchableOpacity>
    </View>
  </View>

  {/* RIGHT SIDE (3 DOT MENU TOP RIGHT) */}
  <TouchableOpacity onPress={openMenu} style={styles.menuBtn}>
    <FontAwesome6 name="ellipsis-vertical" size={16} color={Colors.black} />
  </TouchableOpacity>
</View>

      {/* CONTENT */}
      {!!post.text && <Text style={styles.content}>{post.text}</Text>}

      {/* ACTIONS */}
      {!hideActions && (
  <PostActionsUI postId={post.id} postOwnerId={post.uid} />
)}
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
  justifyContent: "space-between",
  marginBottom: Spacing.sm,
},

  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.gray300,
    marginRight: Spacing.sm,
  },
menuBtn: {
  padding: 6,
},
  avatarImg: {
    width: 36,
    height: 36,
    borderRadius: 18,
    marginRight: Spacing.sm,
  },
repostRow: {
  flexDirection: "row",
  alignItems: "center",
  gap: 6,
  marginBottom: 8,
},

repostText: {
  fontSize: 12,
  fontWeight: "600",
  color: Colors.gray700,
},
  userInfo: {
    flexDirection: "column",
    flex: 1,
  },

  nameRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  left: {
  flexDirection: "row",
  alignItems: "center",
  flex: 1,
},
  name: {
    fontSize: 14,
    fontWeight: "700",
    color: Colors.black,
  },

  dot: {
    fontSize: 12,
    color: Colors.gray500,
  },

  timeInline: {
    fontSize: 12,
    color: Colors.gray700,
  },

  username: {
    fontSize: 12,
    color: Colors.gray700,
    marginTop: 2,
  },

  content: {
    ...Typography.body,
    color: Colors.black,
    lineHeight: 20,
    marginVertical: Spacing.sm,
  },
});
