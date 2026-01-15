import {
  View,
  Text,
  StyleSheet,
  Image,
  TouchableOpacity,
  FlatList,
  Dimensions,
  Alert,
} from "react-native";
import {
  doc,
  getDoc,
  deleteDoc,
  addDoc,
  collection,
} from "firebase/firestore";
import { db } from "@/services/firebase";
import { auth } from "@/services/firebase";
import { FontAwesome6 } from "@expo/vector-icons";
import { Colors } from "@constants/colors";
import { Spacing } from "@constants/spacing";
import { Typography } from "@constants/typography";
import { Post } from "@/types/post";
import { useRouter } from "expo-router";
import { Video, ResizeMode } from "expo-av";
import { useRef, useState, useEffect } from "react";
import { formatPostTime } from "@/utils/formatPostTime";
import PostActionsUI from "@/components/feed/PostActions";

const WIDTH = Dimensions.get("window").width - Spacing.md * 2;

type Props = {
  post: Post;
  context?: "home" | "explore" | "profile";
  showPostTypeIcon?: boolean; // legacy (keep)
  hideActions?: boolean; // legacy (keep)
};

function isVideo(url: string) {
  return (
    url.endsWith(".mp4") ||
    url.endsWith(".mov") ||
    url.endsWith(".webm")
  );
}

function getPostType(post: Post) {
  if (post.media?.length) {
    return isVideo(post.media[0]) ? "video" : "photo";
  }
  return "text";
}

export default function MediaPostCard({
  post,
  context = "home",
  showPostTypeIcon = false,
  hideActions = false,
}: Props) {
  const router = useRouter();
  const videoRef = useRef<Video>(null);
  const [playing, setPlaying] = useState(false);

  const [author, setAuthor] = useState<{
  name?: string;
  username?: string;
  avatar?: string;
} | null>(null);

useEffect(() => {
  const loadAuthor = async () => {
    const snap = await getDoc(
      doc(db, "profiles", post.uid)
    );
    if (snap.exists()) {
      setAuthor(snap.data());
    }
  };

  loadAuthor();
}, [post.uid]);

  const openMenu = () => {
  if (isMyPost) {
    Alert.alert(
      "Post options",
      "",
      [
       {
  text: "Edit",
  onPress: () =>
    router.push(`/post/edit/${post.id}`),
},
        {
          text: "Delete",
          style: "destructive",
          onPress: async () => {
  await deleteDoc(
    doc(db, "posts", post.id)
  );
},
        },
        { text: "Cancel", style: "cancel" },
      ]
    );
  } else {
    Alert.alert(
      "Post options",
      "",
      [
        {
          text: "Report",
          style: "destructive",
          onPress: async () => {
  await addDoc(
  collection(db, "reports"),
  {
    uid: auth.currentUser?.uid,   // ✅ REQUIRED BY RULE
    postId: post.id,
    reportedUserId: post.uid,
    createdAt: new Date(),
  }
);
},
        },
        { text: "Cancel", style: "cancel" },
      ]
    );
  }
};

  const isExplore = context === "explore";
  const isProfile = context === "profile";

  const isMyPost = post.uid === auth.currentUser?.uid;

  const shouldShowActions = !hideActions && !isExplore;
  const shouldShowTypeIcon = isExplore || showPostTypeIcon;

  const media = post.media || [];
  const isVideoPost =
    media.length === 1 && isVideo(media[0]);
  const type = getPostType(post);

  const toggleVideo = async () => {
    if (!videoRef.current) return;
    playing
      ? await videoRef.current.pauseAsync()
      : await videoRef.current.playAsync();
    setPlaying(!playing);
  };

  return (
    <View style={styles.card}>
      {/* HEADER */}
      <View style={styles.header}>
        <View style={styles.left}>
         {author?.avatar ? (
  <Image
    source={{ uri: author.avatar }}
    style={styles.avatar}
  />
) : (
  <View style={styles.avatar} />
)}

          <View>
            <TouchableOpacity
  disabled={isExplore}
  onPress={() =>
    !isExplore &&
    router.push(`/profile/${post.uid}`)
  }
>
  <View style={styles.nameRow}>
    <Text style={styles.name}>
      {author?.name || "—"}
    </Text>

    <Text style={styles.dot}>•</Text>

    <Text style={styles.timeInline}>
      {post.createdAt ? formatPostTime(post.createdAt) : ""}
    </Text>
  </View>

  {!!author?.username && (
    <Text style={styles.username}>
      @{author.username}
    </Text>
  )}
</TouchableOpacity>

          </View>
        </View>

{/* 🔁 REPOST LABEL INSIDE CARD */}
{!!(post as any).repostedByName && (
  <View style={styles.repostRow}>
    <FontAwesome6 name="repeat" size={12} color={Colors.gray700} />
    <Text style={styles.repostText}>
      {(post as any).repostedByName} reposted
    </Text>
  </View>
)}

        {/* ⋮ MENU — NOT FOR EXPLORE */}
        {!isExplore && (
          <TouchableOpacity
            onPress={openMenu}
            style={styles.menuBtn}
          >
            <FontAwesome6
              name="ellipsis-vertical"
              size={16}
              color={Colors.black}
            />
          </TouchableOpacity>
        )}
      </View>

      {/* MEDIA */}
      <View>
        {isVideoPost ? (
          <TouchableOpacity onPress={toggleVideo}>
            <Video
              ref={videoRef}
              source={{ uri: media[0] }}
              style={styles.media}
              resizeMode={ResizeMode.COVER}
              isLooping
            />
          </TouchableOpacity>
        ) : media.length > 1 ? (
          <FlatList
            data={media}
            horizontal
            pagingEnabled
            keyExtractor={(i, idx) => i + idx}
            renderItem={({ item }) => (
              <Image
                source={{ uri: item }}
                style={styles.media}
              />
            )}
          />
        ) : (
          media[0] && (
            <Image
              source={{ uri: media[0] }}
              style={styles.media}
            />
          )
        )}
      </View>

      {/* CAPTION */}
      {post.text && (
        <Text style={styles.caption}>{post.text}</Text>
      )}

      {/* ACTION BAR */}
      {shouldShowActions && (
        <PostActionsUI
          postId={post.id}
          postOwnerId={post.uid}
        />
      )}

      {/* POST TYPE ICON — EXPLORE ONLY */}
      {shouldShowTypeIcon && (
        <View style={styles.typeRow}>
          <FontAwesome6
            name={
              type === "video"
                ? "video"
                : type === "photo"
                ? "image"
                : "file-lines"
            }
            size={16}
            color={Colors.black}
          />
        </View>
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
    elevation: 3,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
  },
  username: {
  fontSize: 12,
  color: Colors.gray700,
},
  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.gray300,
    marginRight: Spacing.sm,
  },
nameRow: {
  flexDirection: "row",
  alignItems: "center",
  gap: 6,
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
dot: {
  color: Colors.gray500,
  fontSize: 12,
},

timeInline: {
  fontSize: 12,
  color: Colors.gray700,
},

  name: {
    fontSize: 14,
    fontWeight: "600",
  },
  time: {
    fontSize: 11,
    color: Colors.gray700,
  },
  media: {
    width: WIDTH,
    height: 260,
    borderRadius: 14,
    marginVertical: Spacing.sm,
  },
  caption: {
    ...Typography.body,
    marginBottom: Spacing.xs,
  },
  typeRow: {
    marginTop: 6,
    alignItems: "flex-start",
  },
  left: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
  },
  menuBtn: {
    padding: 6,
  },
});
