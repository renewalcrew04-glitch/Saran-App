import { TouchableOpacity, Text, StyleSheet } from "react-native";
import { followUser, unfollowUser } from "@/utils/follow";
import { useFollowStatus } from "@/utils/useFollowStatus";

export default function FollowButton({ uid }: { uid: string }) {
  const isFollowing = useFollowStatus(uid);

  const handlePress = async () => {
    if (isFollowing) {
      await unfollowUser(uid);
    } else {
      await followUser(uid);
    }
  };

  return (
    <TouchableOpacity
      style={[
        styles.btn,
        isFollowing && styles.following,
      ]}
      onPress={handlePress}
    >
      <Text
        style={[
          styles.text,
          isFollowing && styles.followingText,
        ]}
      >
        {isFollowing ? "Following" : "Follow"}
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  btn: {
    borderWidth: 1,
    borderColor: "#000",
    paddingVertical: 6,
    paddingHorizontal: 16,
    borderRadius: 20,
  },
  following: {
    backgroundColor: "#000",
  },
  text: {
    fontSize: 13,
    fontWeight: "600",
  },
  followingText: {
    color: "#fff",
  },
});
