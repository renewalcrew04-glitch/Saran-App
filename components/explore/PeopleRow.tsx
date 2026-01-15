import {
  View,
  Text,
  Image,
  StyleSheet,
  TouchableOpacity,
  Animated,
  Pressable,
} from "react-native";
import * as Haptics from "expo-haptics";
import { useRef, useState, memo } from "react";
import { Person as BasePerson } from "@/services/searchPeople";
import { LinearGradient } from "expo-linear-gradient";
import { useRouter } from "expo-router";
import { followUser } from "@/utils/follow";
import { useFollowStatus } from "@/utils/useFollowStatus";
import { auth } from "@/services/firebase";
import { getOrCreateConversation } from "@/services/dm";

type Person = BasePerson & {
  username?: string;
  followsYou?: boolean;
};

function PeopleRow({ person }: { person: Person }) {
  const router = useRouter();
  const { isFollowing } = useFollowStatus(person.uid);

  const [optimisticFollow, setOptimisticFollow] =
    useState<boolean | null>(null);

  const following = optimisticFollow ?? isFollowing;
  const scale = useRef(new Animated.Value(1)).current;

  const animatePress = () => {
    Animated.sequence([
      Animated.spring(scale, {
        toValue: 0.94,
        useNativeDriver: true,
      }),
      Animated.spring(scale, {
        toValue: 1,
        useNativeDriver: true,
      }),
    ]).start();
  };

  const onFollow = () => {
    const currentUid = auth.currentUser?.uid;
    if (!currentUid) return;

    setOptimisticFollow(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    animatePress();

    followUser(currentUid, person.uid).catch(() => {
      setOptimisticFollow(false); // rollback
    });
  };

  const openChat = async () => {
    const currentUid = auth.currentUser?.uid;
    if (!currentUid) return;

    const cid = await getOrCreateConversation(currentUid, person.uid);
    router.push(`/messages/chat?cid=${cid}`);
  };

  return (
    <View style={styles.row}>
      {/* LEFT */}
      <TouchableOpacity
        style={styles.left}
        onPress={() => router.push(`/profile/${person.uid}`)}
      >
        <Image
          source={{
            uri:
              person.avatar ||
              "https://ui-avatars.com/api/?name=User&background=000000&color=ffffff",
          }}
          style={styles.avatar}
        />

        <View style={styles.textWrap}>
          <Text style={styles.name} numberOfLines={1}>
            {person.name}
          </Text>

          <Text style={styles.username} numberOfLines={1}>
            @{person.username || person.name?.toLowerCase().replace(/\s+/g, "")}
          </Text>

          {person.followsYou && (
            <Text style={styles.mutualBadge}>Follows you</Text>
          )}
        </View>
      </TouchableOpacity>

      {/* RIGHT */}
      {following ? (
        <Animated.View
          style={[styles.followingPill, { transform: [{ scale }] }]}
        >
          <Text style={styles.followingText}>Following</Text>
        </Animated.View>
      ) : (
        <Animated.View style={{ transform: [{ scale }] }}>
          <Pressable onPress={onFollow}>
            <LinearGradient
              colors={["#000000", "#2b2b2b", "#000000"]}
              style={styles.followGradient}
            >
              <View style={styles.followGloss} />
              <Text style={styles.followText}>Follow</Text>
            </LinearGradient>
          </Pressable>
        </Animated.View>
      )}
    </View>
  );
}

export default memo(PeopleRow);

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: 14,
    paddingHorizontal: 14,
    marginBottom: 10,
    borderRadius: 16,
    backgroundColor: "#fff",
    shadowColor: "#000",
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  left: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    marginRight: 12,
    backgroundColor: "#eee",
  },
  textWrap: { flex: 1 },
  name: {
    fontSize: 15,
    fontWeight: "600",
    color: "#111",
  },
  username: {
    fontSize: 12,
    color: "#777",
    marginTop: 2,
  },
  mutualBadge: {
    fontSize: 11,
    color: "#4CAF50",
    marginTop: 2,
  },
  followGradient: {
    paddingHorizontal: 18,
    paddingVertical: 7,
    borderRadius: 18,
    overflow: "hidden",
  },
  followGloss: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    height: "45%",
    backgroundColor: "rgba(255,255,255,0.12)",
  },
  followText: {
    fontSize: 12,
    fontWeight: "600",
    color: "#fff",
  },
  followingPill: {
    paddingHorizontal: 18,
    paddingVertical: 7,
    borderRadius: 18,
    backgroundColor: "#f2f2f2",
    borderWidth: 1,
    borderColor: "#ddd",
  },
  followingText: {
    fontSize: 12,
    fontWeight: "600",
    color: "#111",
  },
});
