import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
} from "react-native";
import { useEffect, useState } from "react";
import {
  collection,
  onSnapshot,
  orderBy,
  query,
  updateDoc,
  doc,
  getDoc,
} from "firebase/firestore";
import { auth, db } from "@/services/firebase";
import { Notification } from "@/types/notification";
import { useRouter } from "expo-router";
import { getNotificationText } from "@/services/notificationText";
import { formatPostTime } from "@/utils/formatPostTime";
import FallbackAvatar from "@/components/ui/FallbackAvatar";
import { Ionicons } from "@expo/vector-icons";

/* ---------------- ROW ---------------- */

function NotificationRow({
  item,
  onPress,
}: {
  item: Notification;
  onPress: () => void;
}) {
  const [profile, setProfile] = useState<{
    name?: string;
    avatar?: string;
  } | null>(null);

  useEffect(() => {
    if (!item.fromUserId) return;

    getDoc(doc(db, "profiles", item.fromUserId)).then(
      (snap) => {
        if (snap.exists()) {
          setProfile(snap.data());
        }
      }
    );
  }, [item.fromUserId]);

  return (
    <TouchableOpacity
      style={[styles.row, !item.read && styles.unread]}
      onPress={onPress}
    >
      <FallbackAvatar
        uri={profile?.avatar}
        size={44}
      />

      <View style={{ flex: 1, marginLeft: 12 }}>
        <Text>
          <Text style={styles.bold}>
            {profile?.name ?? "User"}{" "}
          </Text>
          {getNotificationText(item)}
        </Text>

        <Text style={styles.time}>
          {formatPostTime(item.createdAt)}
        </Text>
      </View>

      <Ionicons
        name="chevron-forward"
        size={18}
        color="#aaa"
      />
    </TouchableOpacity>
  );
}

/* ---------------- SCREEN ---------------- */

export default function Notifications() {
  const uid = auth.currentUser?.uid;
  const router = useRouter();
  const [notifications, setNotifications] =
    useState<Notification[]>([]);

  useEffect(() => {
    if (!uid) return;

    const q = query(
      collection(db, "notifications", uid, "items"),
      orderBy("createdAt", "desc")
    );

    return onSnapshot(q, (snap) => {
      setNotifications(
        snap.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Omit<Notification, "id">),
        }))
      );
    });
  }, [uid]);

  const openNotification = async (n: Notification) => {
    if (!uid) return;

    if (!n.read) {
      await updateDoc(
        doc(db, "notifications", uid, "items", n.id),
        { read: true }
      );
    }

    if (n.entityType === "post" && n.entityId) {
      router.push(`/post/${n.entityId}`);
    }

    if (n.type === "follow") {
      router.push(`/profile/${n.fromUserId}`);
    }

    if (n.type === "dm" && n.entityId) {
      router.push(`/messages/chat?cid=${n.entityId}`);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.header}>Notifications</Text>

      <FlatList
        data={notifications}
        keyExtractor={(i) => i.id}
        renderItem={({ item }) => (
          <NotificationRow
            item={item}
            onPress={() =>
              openNotification(item)
            }
          />
        )}
        ListEmptyComponent={
          <Text style={styles.empty}>
            No notifications
          </Text>
        }
      />
    </View>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    padding: 16,
  },
  header: {
    fontSize: 26,
    fontWeight: "600",
    marginBottom: 12,
  },
  row: {
    flexDirection: "row",
    paddingVertical: 14,
    alignItems: "center",
  },
  unread: {
    backgroundColor: "#f7f7f7",
  },
  bold: {
    fontWeight: "600",
  },
  time: {
    marginTop: 4,
    fontSize: 12,
    color: "#888",
  },
  empty: {
    marginTop: 40,
    textAlign: "center",
    color: "#777",
  },
});
