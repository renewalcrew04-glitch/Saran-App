import {
  View,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
} from "react-native";
import { useRouter } from "expo-router";
import { useFollowStatus } from "@/utils/useFollowStatus";
import { followUser, unfollowUser } from "@/utils/follow";

export default function PeopleListRow({
  person,
  currentUid,
}: {
  person: any;
  currentUid: string;
}) {
  const router = useRouter();
  const { isFollowing } = useFollowStatus(person.uid);

  return (
    <View style={styles.row}>
      {/* AVATAR */}
      <TouchableOpacity
        onPress={() => router.push(`/profile/${person.uid}`)}
      >
        <Image
          source={{
            uri:
              person.avatar ||
              "https://ui-avatars.com/api/?name=User",
          }}
          style={styles.avatar}
        />
      </TouchableOpacity>

      {/* NAME */}
      <TouchableOpacity
        style={styles.center}
        onPress={() =>
          router.push(`/profile/${person.uid}`)
        }
      >
        <Text style={styles.name} numberOfLines={1}>
          {person.name}
        </Text>
      </TouchableOpacity>

      {/* FOLLOW / FOLLOWING */}
      <TouchableOpacity
        style={[
          styles.followBtn,
          isFollowing && styles.followingBtn,
        ]}
        onPress={() =>
          isFollowing
            ? unfollowUser(currentUid, person.uid)
            : followUser(currentUid, person.uid)
        }
      >
        <Text
          style={[
            styles.followText,
            isFollowing && styles.followingText,
          ]}
        >
          {isFollowing ? "Following" : "Follow"}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

/* 🔒 SAME STYLES — COPIED, NOT MODIFIED */

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderColor: "#eee",
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
  },
  center: {
    flex: 1,
    marginLeft: 12,
  },
  name: {
    fontSize: 14,
    fontWeight: "600",
  },
  followBtn: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: "#000",
  },
  followingBtn: {
    backgroundColor: "#f2f2f2",
  },
  followText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "600",
  },
  followingText: {
    color: "#000",
  },
});
