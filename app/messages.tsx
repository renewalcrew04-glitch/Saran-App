import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  Alert,
  Image,
} from "react-native";
import { useEffect, useState, useRef, useMemo } from "react";
import {
  collection,
  onSnapshot,
  orderBy,
  query,
  where,
  getDoc,
  doc,
  updateDoc,
} from "firebase/firestore";
import { auth, db } from "@/services/firebase";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { formatPostTime } from "@/utils/formatPostTime";
import FallbackAvatar from "@/components/ui/FallbackAvatar";
import {
  muteConversation,
  archiveConversation,
} from "@/services/dm";
import { Swipeable } from "react-native-gesture-handler";

/* ---------------- TYPES ---------------- */

type Conversation = {
  id: string;
  participants: string[];
  lastMessage: string;
  lastMessageAt: any;
  unread?: Record<string, number>;
  archived?: Record<string, boolean>;
  muted?: Record<string, boolean>;
  pinned?: Record<string, boolean>;
};

type UserLite = {
  name?: string;
  avatar?: string;
  online?: boolean;
};

/* ---------------- SCREEN ---------------- */

export default function Messages() {
  const router = useRouter();
  const uid = auth.currentUser?.uid!;
  const [search, setSearch] = useState("");
  const [conversations, setConversations] =
    useState<Conversation[]>([]);

  const profileCache = useRef<Record<string, UserLite>>(
    {}
  );
  const [, forceRender] = useState(0);

  /* ---------------- LOAD CONVERSATIONS ---------------- */

  useEffect(() => {
    const q = query(
      collection(db, "conversations"),
      where("participants", "array-contains", uid),
      orderBy("lastMessageAt", "desc")
    );

    return onSnapshot(q, (snap) => {
      setConversations(
        snap.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Omit<Conversation, "id">),
        }))
      );
    });
  }, [uid]);

  /* ---------------- LOAD PROFILE LITE ---------------- */

  const loadProfile = async (otherUid: string) => {
    if (profileCache.current[otherUid]) return;

    const snap = await getDoc(
      doc(db, "profiles", otherUid)
    );
    if (!snap.exists()) return;

    const data = snap.data();

    profileCache.current[otherUid] = {
      name: data.name ?? "User",
      avatar: data.avatar,
      online: data.online === true,
    };

    forceRender((v) => v + 1);
  };

  /* ---------------- FILTER + SORT ---------------- */

  const visible = useMemo(() => {
    return conversations
      .filter((c) => !c.archived?.[uid])
      .map((c) => {
        const otherUid =
          c.participants.find((p) => p !== uid) ?? "";
        const profile =
          profileCache.current[otherUid];

        return {
          ...c,
          otherUid,
          otherName: profile?.name ?? "",
        };
      })
      .filter((c) =>
        c.otherName
          .toLowerCase()
          .includes(search.toLowerCase())
      )
      .sort((a, b) => {
        const aPinned = a.pinned?.[uid] ? 1 : 0;
        const bPinned = b.pinned?.[uid] ? 1 : 0;
        return bPinned - aPinned;
      });
  }, [conversations, search, uid]);

  /* ---------------- ACTIONS ---------------- */

  const togglePin = async (cid: string, v: boolean) => {
    await updateDoc(doc(db, "conversations", cid), {
      [`pinned.${uid}`]: v,
    });
  };

  /* ---------------- SWIPE ACTION UI ---------------- */

  const renderRightActions = (item: any) => {
    const isPinned = item.pinned?.[uid];
    const isMuted = item.muted?.[uid];

    return (
      <View style={styles.swipeWrap}>
        <Action
          label={isPinned ? "Unpin" : "Pin"}
          color="#000"
          onPress={() => togglePin(item.id, !isPinned)}
        />
        <Action
          label={isMuted ? "Unmute" : "Mute"}
          color="#555"
          onPress={() =>
            muteConversation(
              item.id,
              uid,
              !isMuted
            )
          }
        />
        <Action
          label="Archive"
          color="#b00020"
          onPress={() =>
            archiveConversation(item.id, uid, true)
          }
        />
      </View>
    );
  };

  /* ---------------- EMPTY STATE ---------------- */

  const Empty = () => (
    <View style={styles.empty}>
      <Ionicons
        name="chatbubble-outline"
        size={48}
        color="#bbb"
      />
      <Text style={styles.emptyTitle}>
        No messages yet
      </Text>
      <Text style={styles.emptySub}>
        Start a conversation from someone’s profile
      </Text>
    </View>
  );

  /* ---------------- UI ---------------- */

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.header}>Messages</Text>

      {/* SEARCH */}
      <View style={styles.searchBox}>
        <Ionicons name="search" size={18} />
        <TextInput
          placeholder="Search by name..."
          value={search}
          onChangeText={setSearch}
          style={styles.searchInput}
        />
      </View>

      <FlatList
        data={visible}
        keyExtractor={(i) => i.id}
        ListEmptyComponent={Empty}
        renderItem={({ item }) => {
          const {
            id,
            otherUid,
            lastMessage,
            lastMessageAt,
            unread,
            muted,
            pinned,
          } = item;

          if (otherUid) loadProfile(otherUid);
          const profile =
            profileCache.current[otherUid];

          const unreadCount =
            unread?.[uid] ?? 0;

          return (
            <Swipeable
              renderRightActions={() =>
                renderRightActions(item)
              }
            >
              <TouchableOpacity
                style={styles.row}
                onPress={() =>
                  router.push(
                    `/messages/chat?cid=${id}`
                  )
                }
              >
                {/* AVATAR */}
                <View style={styles.avatarWrap}>
                  {profile?.avatar ? (
                    <Image
                      source={{
                        uri: profile.avatar,
                      }}
                      style={styles.avatar}
                    />
                  ) : (
                    <FallbackAvatar size={48} />
                  )}

                  {profile?.online && (
                    <View style={styles.onlineDot} />
                  )}
                </View>

                {/* CENTER */}
                <View style={styles.center}>
                  <View style={styles.nameRow}>
                    <Text
                      style={styles.name}
                      numberOfLines={1}
                    >
                      {profile?.name ?? "User"}
                    </Text>

                    {muted?.[uid] && (
                      <Ionicons
                        name="notifications-off-outline"
                        size={14}
                        color="#999"
                        style={{ marginLeft: 6 }}
                      />
                    )}

                    {pinned?.[uid] && (
                      <Ionicons
                        name="pin"
                        size={14}
                        color="#000"
                        style={{ marginLeft: 6 }}
                      />
                    )}
                  </View>

                  <Text
                    style={styles.preview}
                    numberOfLines={1}
                  >
                    {lastMessage || "Photo"}
                  </Text>
                </View>

                {/* RIGHT */}
                <View style={styles.right}>
                  <Text style={styles.time}>
                    {formatPostTime(
                      lastMessageAt
                    )}
                  </Text>

                  {unreadCount > 0 && (
                    <View style={styles.badge}>
                      <Text
                        style={styles.badgeText}
                      >
                        {unreadCount}
                      </Text>
                    </View>
                  )}
                </View>
              </TouchableOpacity>
            </Swipeable>
          );
        }}
      />
    </SafeAreaView>
  );
}

/* ---------------- SWIPE BUTTON ---------------- */

function Action({
  label,
  color,
  onPress,
}: {
  label: string;
  color: string;
  onPress: () => void;
}) {
  return (
    <TouchableOpacity
      onPress={onPress}
      style={[
        styles.actionBtn,
        { backgroundColor: color },
      ]}
    >
      <Text style={styles.actionText}>
        {label}
      </Text>
    </TouchableOpacity>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#fff", paddingHorizontal: 16 },
  header: { fontSize: 26, fontWeight: "600", marginVertical: 12 },

  searchBox: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#f2f2f2",
    borderRadius: 14,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: 12,
  },
  searchInput: { flex: 1, marginLeft: 8 },

  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 14,
    borderBottomWidth: 0.5,
    borderColor: "#eee",
  },

  avatarWrap: { position: "relative" },
  avatar: { width: 48, height: 48, borderRadius: 24 },

  onlineDot: {
    position: "absolute",
    bottom: 2,
    right: 2,
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: "#2ecc71",
    borderWidth: 2,
    borderColor: "#fff",
  },

  center: { flex: 1, marginLeft: 12 },
  nameRow: { flexDirection: "row", alignItems: "center" },
  name: { fontSize: 16, fontWeight: "600" },
  preview: { color: "#666", marginTop: 2 },

  right: { alignItems: "flex-end", gap: 6 },
  time: { fontSize: 12, color: "#888" },

  badge: {
    minWidth: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: "#000",
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 6,
  },
  badgeText: { color: "#fff", fontSize: 11, fontWeight: "600" },

  swipeWrap: {
    flexDirection: "row",
    alignItems: "center",
  },
  actionBtn: {
    width: 70,
    justifyContent: "center",
    alignItems: "center",
  },
  actionText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "600",
  },

  empty: {
    alignItems: "center",
    paddingTop: 100,
  },
  emptyTitle: {
    marginTop: 12,
    fontSize: 16,
    fontWeight: "600",
  },
  emptySub: {
    marginTop: 6,
    color: "#888",
    textAlign: "center",
    paddingHorizontal: 40,
  },
});
