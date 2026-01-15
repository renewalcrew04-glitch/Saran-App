import {
  View,
  FlatList,
  Image,
  TouchableOpacity,
  Text,
  StyleSheet,
  Dimensions,
} from "react-native";
import { Post } from "@/types/post";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { savePost } from "@/services/savePost";
import { memo } from "react";

const SIZE = Dimensions.get("window").width / 3;

type Props = {
  posts: Post[];
  ListHeaderComponent?: React.ReactElement | null;
};

function ProfilePostGrid({ posts, ListHeaderComponent }: Props) {
  const router = useRouter();

  return (
    <FlatList
      data={posts}
      numColumns={3}
      ListHeaderComponent={ListHeaderComponent}
      keyExtractor={(item: any) =>
  item.type === "repost"
    ? `repost-${item.id}-${item.repostedByUid || item.uid}`
    : item.id
}
      renderItem={({ item }) => (
        <TouchableOpacity
          style={styles.item}
          activeOpacity={0.85}
          onPress={() =>
            router.push({
              pathname: "/profile/feed",
              params: {
                uid: item.uid,
                postId: item.id,
              },
            })
          }
        >
          <TouchableOpacity
            style={styles.bookmark}
            onPress={(e) => {
              e.stopPropagation();
              savePost(item.id, item.uid);
            }}
          >
            <Ionicons name="bookmark-outline" size={18} color="#000" />
          </TouchableOpacity>

          {item.media?.[0] ? (
            <Image
              source={{ uri: item.media[0] }}
              style={styles.image}
            />
          ) : (
            <View style={styles.textPost}>
              <Text numberOfLines={4} style={styles.text}>
                {item.text}
              </Text>
            </View>
          )}
        </TouchableOpacity>
      )}
    />
  );
}

export default memo(ProfilePostGrid);

const styles = StyleSheet.create({
  item: {
    width: SIZE,
    aspectRatio: 1,
    borderWidth: 0.5,
    borderColor: "#eee",
  },
  bookmark: {
    position: "absolute",
    top: 6,
    right: 6,
    zIndex: 10,
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 4,
  },
  image: { width: "100%", height: "100%" },
  textPost: {
    flex: 1,
    backgroundColor: "#f2f2f2",
    justifyContent: "center",
    padding: 8,
  },
  text: { fontSize: 13, textAlign: "center" },
});
