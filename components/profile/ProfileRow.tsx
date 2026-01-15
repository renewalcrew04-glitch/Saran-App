import {
  View,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { useEffect, useState } from "react";
import { useRouter } from "expo-router";
import { doc, getDoc } from "firebase/firestore";
import { db, auth } from "@/services/firebase";
import { followUser, unfollowUser } from "@/utils/follow";
import { useFollowStatus } from "@/utils/useFollowStatus";
import FallbackAvatar from "@/components/ui/FallbackAvatar";
import { Ionicons } from "@expo/vector-icons";
import { getOrCreateConversation } from "@/services/dm";

type Profile = {
  uid: string;
  name?: string;
  avatar?: string;
  username?: string;
};

export default function ProfileRow({
  uid,
  showFollow,
}: {
  uid: string;
  showFollow?: boolean;
}) {
  const router = useRouter();
  const { isFollowing } = useFollowStatus(uid);
  const [profile, setProfile] = useState<Profile | null>(null);

  useEffect(() => {
    if (!auth.currentUser) return;

    getDoc(doc(db, "profiles", uid)).then((snap) => {
      if (snap.exists()) {
        setProfile({ uid, ...(snap.data() as any) });
      }
    });
  }, [uid]);

  if (!profile) return null;

  const openChat = async () => {
    const currentUid = auth.currentUser?.uid;
    if (!currentUid) return;

    const cid = await getOrCreateConversation(currentUid, uid);
    router.push(`/messages/chat?cid=${cid}`);
  };

  return (
    <View style={styles.row}>
      {/* AVATAR */}
      <TouchableOpacity
        onPress={() => router.push(`/profile/${uid}`)}
      >
        {profile.avatar ? (
          <Image source={{ uri: profile.avatar }} style={styles.avatar} />
        ) : (
          <FallbackAvatar size={40} />
        )}
      </TouchableOpacity>

      {/* NAME */}
      <TouchableOpacity
        style={styles.center}
        onPress={() => router.push(`/profile/${uid}`)}
      >
        <View>
  <Text style={styles.name}>
    {profile.name ?? "User"}
  </Text>

  <Text style={styles.username}>
    @{profile.username || (profile.name ?? "user").toLowerCase()}
  </Text>
</View>
      </TouchableOpacity>

      {/* ACTION */}
      {showFollow && (
        isFollowing ? (
          <TouchableOpacity
            style={styles.dmBtn}
            onPress={openChat}
          >
            <Ionicons
              name="chatbubble-outline"
              size={18}
            />
          </TouchableOpacity>
        ) : (
          <TouchableOpacity
  activeOpacity={0.85}
  onPress={() => {
    const currentUid = auth.currentUser?.uid;
    if (!currentUid) return;
    followUser(currentUid, uid);
  }}
>
  <LinearGradient
    colors={["#000000", "#2b2b2b", "#000000"]}
    start={{ x: 0, y: 0 }}
    end={{ x: 1, y: 1 }}
    style={styles.followGradient}
  >
    <View style={styles.followGloss} />
    <Text style={styles.followText}>Follow</Text>
  </LinearGradient>
</TouchableOpacity>
        )
      )}
    </View>
  );
}

const styles = StyleSheet.create({
 row: {
  flexDirection: "row",
  alignItems: "center",
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
followGradient: {
  paddingHorizontal: 18,
  paddingVertical: 7,
  borderRadius: 18,
},

followGloss: {
  position: "absolute",
  top: 0,
  left: 0,
  right: 0,
  height: "45%",
  backgroundColor: "rgba(255,255,255,0.12)",
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
  username: {
  fontSize: 12,
  color: "#777",
  marginTop: 2,
},
  followBtn: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: "#000",
    borderRadius: 20,
  },
  followText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "600",
  },
  dmBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "#ddd",
    alignItems: "center",
    justifyContent: "center",
  },
});
