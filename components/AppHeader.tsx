import { View, Text, StyleSheet, TouchableOpacity } from "react-native";
import { useRouter } from "expo-router";
import { FontAwesome6, Ionicons } from "@expo/vector-icons";
import { Colors } from "@constants/colors";
import { Typography } from "@constants/typography";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useEffect, useState } from "react";
import { useAuthReady } from "@/hooks/useAuthReady";
import { listenUnreadNotifications } from "@/services/notificationCount";

type AppHeaderProps = {
  title?: string;
  showBack?: boolean;
};

export default function AppHeader({
  title = "SARAN",
  showBack = false,
}: AppHeaderProps) {
  const router = useRouter();

  const insets = useSafeAreaInsets();
  const [unreadCount, setUnreadCount] = useState(0);
  const user = useAuthReady();

useEffect(() => {
  if (!user) return;

  const unsub = listenUnreadNotifications(
    user.uid,
    (count) => {
      setUnreadCount(count);
    }
  );

  return unsub;
}, [user?.uid]);

  return (
    <View
  style={[
    styles.container,
    { paddingTop: insets.top },
  ]}
>
      {/* LEFT */}
      <View style={styles.left}>
        {showBack ? (
          <TouchableOpacity onPress={() => router.back()}>
            <Ionicons
              name="chevron-back"
              size={22}
              color={Colors.black}
            />
          </TouchableOpacity>
        ) : (
          <Text style={styles.logo}>{title}</Text>
        )}
      </View>

      {/* CENTER */}
      {showBack && (
        <View style={styles.center}>
          <Text style={styles.centerTitle}>{title}</Text>
        </View>
      )}

      {/* RIGHT */}
      <View style={styles.right}>
        {!showBack && (
          <>
            {/* Notifications */}
            <TouchableOpacity
  onPress={() => router.push("/notifications")}
>
  <Ionicons
    name="notifications-outline"
    size={22}
    color="#000"
  />

  {unreadCount > 0 && (
    <View
      style={{
        position: "absolute",
        top: -4,
        right: -6,
        backgroundColor: "red",
        width: 18,
        height: 18,
        borderRadius: 9,
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <Text
        style={{
          color: "#fff",
          fontSize: 11,
          fontWeight: "700",
        }}
      >
        {unreadCount}
      </Text>
    </View>
  )}
</TouchableOpacity>

            {/* Messages */}
            <TouchableOpacity
              style={styles.iconWrap}
              onPress={() => router.push("/messages")}
            >
              <FontAwesome6
                name="comment"
                size={20}
                color={Colors.black}
              />
            </TouchableOpacity>
          </>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingBottom: 12,
    flexDirection: "row",
    alignItems: "center",
    borderBottomWidth: 1,
    borderBottomColor: Colors.gray200,
    backgroundColor: Colors.white,
  },

  left: {
    flex: 1,
    justifyContent: "center",
  },

  center: {
    position: "absolute",
    left: 0,
    right: 0,
    alignItems: "center",
  },

  right: {
    flexDirection: "row",
    gap: 18,
  },

  logo: {
    ...Typography.title,
    color: Colors.black,
  },

  centerTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: Colors.black,
  },

  iconWrap: {
    position: "relative",
  },

  badge: {
    position: "absolute",
    top: -6,
    right: -8,
    backgroundColor: Colors.black,
    borderRadius: 8,
    minWidth: 16,
    height: 16,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 3,
  },

  badgeText: {
    fontSize: 10,
    color: Colors.white,
    fontWeight: "600",
  },
});
