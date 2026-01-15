import { View } from "react-native";
import { useLocalSearchParams } from "expo-router";
import PostComments from "@/components/post/PostComments";

export default function PostCommentsScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  if (!id) return null;

  return (
    <View style={{ flex: 1 }}>
      <PostComments postId={id} />
    </View>
  );
}
