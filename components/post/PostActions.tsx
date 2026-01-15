import { View, TouchableOpacity } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useEffect, useState } from "react";
import { useRouter } from "expo-router";

import {
  likePost,
  unlikePost,
  repostPost,
} from "@/services/postActions";
import { hasLiked } from "@/services/postLikes";
import { savePost } from "@/services/savePost";
import { sharePost } from "@/services/sharePost";

export default function PostActions({
  postId,
  postOwnerId,
}: {
  postId: string;
  postOwnerId: string;
}) {
  const router = useRouter();
  const [liked, setLiked] = useState(false);

  useEffect(() => {
    hasLiked(postId).then(setLiked);
  }, [postId]);

  return (
    <View
      style={{
        flexDirection: "row",
        gap: 20,
        paddingVertical: 8,
      }}
    >
      {/* ❤️ LIKE */}
      <TouchableOpacity
        onPress={async () => {
          if (liked) {
            await unlikePost(postId);
            setLiked(false);
          } else {
            await likePost(postId, postOwnerId);
            setLiked(true);
          }
        }}
      >
        <Ionicons
          name={liked ? "heart" : "heart-outline"}
          size={22}
          color={liked ? "red" : "black"}
        />
      </TouchableOpacity>

      {/* 💬 COMMENT */}
      <TouchableOpacity
        onPress={() =>
          router.push(`/post/${postId}`)
        }
      >
        <Ionicons
          name="chatbubble-outline"
          size={22}
        />
      </TouchableOpacity>

      {/* 🔁 REPOST */}
      <TouchableOpacity
        onPress={() =>
          repostPost(postId, postOwnerId)
        }
      >
        <Ionicons
          name="repeat-outline"
          size={22}
        />
      </TouchableOpacity>

      {/* 🔖 SAVE */}
      <TouchableOpacity
        onPress={() =>
          savePost(postId, postOwnerId)
        }
      >
        <Ionicons
          name="bookmark-outline"
          size={22}
        />
      </TouchableOpacity>

      {/* 📤 SHARE */}
      <TouchableOpacity
        onPress={() =>
          sharePost(postId, postOwnerId)
        }
      >
        <Ionicons
          name="share-social-outline"
          size={22}
        />
      </TouchableOpacity>
    </View>
  );
}
