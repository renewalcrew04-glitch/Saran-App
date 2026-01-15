import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from "react-native";
import { useEffect, useState } from "react";
import { useLocalSearchParams, useRouter } from "expo-router";
import { auth } from "@/services/firebase";
import {
  fetchFollowersPaginated,
  fetchFollowingPaginated,
} from "@/services/followLists";
import {
  getOrCreateConversation,
  sendMessage,
} from "@/services/dm";
import { notify } from "@/services/notify";
import FallbackAvatar from "@/components/ui/FallbackAvatar";
import { Ionicons } from "@expo/vector-icons";

type UserItem = {
  uid: string;
  name?: string;
  avatar?: string;
};

export default function ShareScreen() {
  const { postId } = useLocalSearchParams<{
    postId: string;
  }>();
  const router = useRouter();
  const currentUid = auth.currentUser?.uid!;

  const [users, setUsers] = useState<UserItem[]>([]);
  const [selected, setSelected] = useState<Set<string>>(
    new Set()
  );

  /* ---------------- LOAD FOLLOW + FOLLOWERS ---------------- */

  useEffect(() => {
    async function load() {
      const following = await fetchFollowingPaginated(
        currentUid
      );
      const followers = await fetchFollowersPaginated(
        currentUid
      );

      const map = new Map<string, UserItem>();
      [...following.data, ...followers.data].forEach(
        (u: any) => {
          map.set(u.uid, {
            uid: u.uid,
            name: u.name,
            avatar: u.avatar,
          });
        }
      );

      setUsers(Array.from(map.values()));
    }

    load();
  }, []);

  /* ---------------- TOGGLE SELECT ---------------- */

  const toggle = (uid: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(uid) ? next.delete(uid) : next.add(uid);
      return next;
    });
  };

  /* ---------------- SHARE ACTION ---------------- */

  const share = async () => {
    if (!postId || selected.size === 0) return;

    try {
      for (const otherUid of selected) {
        const conversationId =
          await getOrCreateConversation(
            currentUid,
            otherUid
          );

        await sendMessage({
          conversationId,
          senderUid: currentUid,
          receiverUid: otherUid,
          text: `[POST]::${postId}`,
        });

        await notify({
          userId: otherUid,
          fromUserId: currentUid,
          type: "share",
          entityType: "post",
          entityId: postId,
          message: "shared a post with you",
        });
      }

      Alert.alert("Shared", "Post sent");
      router.back();
    } catch {
      Alert.alert("Error", "Share failed");
    }
  };

  /* ---------------- UI ---------------- */

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        Share post
      </Text>

      <FlatList
        data={users}
        keyExtractor={(u) => u.uid}
        renderItem={({ item }) => {
          const isSelected =
            selected.has(item.uid);

          return (
            <TouchableOpacity
              style={styles.row}
              onPress={() => toggle(item.uid)}
            >
              <FallbackAvatar
                uri={item.avatar}
                size={42}
              />
              <Text style={styles.name}>
                {item.name || "User"}
              </Text>

              {isSelected && (
                <Ionicons
                  name="checkmark-circle"
                  size={20}
                  color="#000"
                />
              )}
            </TouchableOpacity>
          );
        }}
      />

      {selected.size > 0 && (
        <TouchableOpacity
          style={styles.shareBtn}
          onPress={share}
        >
          <Text style={styles.shareText}>
            Share ({selected.size})
          </Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: "#fff",
  },

  title: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: 16,
  },

  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingVertical: 12,
    borderBottomWidth: 0.5,
    borderColor: "#eee",
  },

  name: {
    flex: 1,
    fontSize: 15,
    fontWeight: "500",
  },

  shareBtn: {
    marginTop: 12,
    padding: 14,
    borderRadius: 12,
    backgroundColor: "#000",
    alignItems: "center",
  },

  shareText: {
    color: "#fff",
    fontWeight: "600",
  },
});
