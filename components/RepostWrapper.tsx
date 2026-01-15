import { View, StyleSheet } from "react-native";
import { Spacing } from "@constants/spacing";
import { Post } from "@/types/post";
import PostCard from "@/components/PostCard";
import MediaPostCard from "@/components/MediaPostCard";

type Props = {
  post: Post;
};

export default function RepostWrapper({ post }: Props) {
  return (
    <View style={styles.wrap}>
      {post.type === "text" ? (
        <PostCard post={{ ...post, type: "text" }} />
      ) : (
        <MediaPostCard post={{ ...post }} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginTop: Spacing.sm,
  },
});
