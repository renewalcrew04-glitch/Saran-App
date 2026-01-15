import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useEffect, useState } from "react";
import { Alert } from "react-native";
import * as PostService from "@/services/postActions";
import { savePost } from "@/services/savePost";

type Props = {
  postId: string;
  postOwnerId: string;
};

export default function PostActionsUI({
  postId,
  postOwnerId,
}: Props) {
  const router = useRouter();
  const [stats, setStats] = useState({
    likes: 0,
    comments: 0,
    reposts: 0,
    shares: 0,
    likedByMe: false,
    repostedByMe: false,
  });

  useEffect(() => {
    return PostService.subscribePostStats(
      postId,
      setStats
    );
  }, [postId]);

  return (
    <View style={styles.row}>
      {/* ❤️ LIKE */}
      <Action
        icon={
          stats.likedByMe
            ? "heart"
            : "heart-outline"
        }
        count={stats.likes}
        onPress={() =>
          stats.likedByMe
            ? PostService.unlikePost(postId)
            : PostService.likePost(
                postId,
                postOwnerId
              )
        }
      />

      {/* 💬 COMMENT */}
      <Action
        icon="chatbubble-outline"
        count={stats.comments}
        onPress={() =>
          router.push({
            pathname: "/post/[id]",
            params: { id: postId },
          })
        }
      />

      {/* 🔁 REPOST */}
<Action
  icon="repeat-outline"
  count={stats.reposts}
  onPress={() => {
    if (stats.repostedByMe) {
      // already reposted → undo menu
      Alert.alert("Repost", "", [
        {
          text: "Undo repost",
          style: "destructive",
          onPress: () => PostService.unrepostPost(postId),
        },
        { text: "Cancel", style: "cancel" },
      ]);
    } else {
      // not reposted → repost menu
      Alert.alert("Repost", "", [
        {
          text: "Repost",
          onPress: () => PostService.repostPost(postId, postOwnerId),
        },
        {
  text: "Quote",
  onPress: () => {
    router.push(`/post/quote/${postId}`);
  },
},
        { text: "Cancel", style: "cancel" },
      ]);
    }
  }}
/>

      {/* 🔖 SAVE */}
      <Action
        icon="bookmark-outline"
        count={0}
        onPress={() =>
          savePost(postId, postOwnerId)
        }
      />

      {/* 📤 SHARE */}
      <TouchableOpacity
        onPress={() =>
          router.push({
            pathname: "/share",
            params: { postId },
          })
        }
        style={styles.share}
      >
        <Ionicons
          name="share-social-outline"
          size={17}
        />
      </TouchableOpacity>
    </View>
  );
}

function Action({
  icon,
  count,
  onPress,
}: {
  icon: any;
  count: number;
  onPress?: () => void;
}) {
  return (
    <TouchableOpacity
      style={styles.action}
      onPress={onPress}
      activeOpacity={0.7}
    >
      <Ionicons
        name={icon}
        size={17}
      />
      <Text style={styles.count}>
        {count}
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,            // 🔥 reduced from 20
    marginTop: 8,
  },

  action: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,             // 🔥 reduced from 4
  },

  count: {
    fontSize: 11,       // 🔥 slightly smaller
    color: "#555",
  },

  share: {
    marginLeft: 4,      // 🔥 closer to others
  },
});
