 import { Stack, useRouter } from "expo-router";
import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { Ionicons, FontAwesome6 } from "@expo/vector-icons";

export default function ProfileLayout() {
  const router = useRouter();
  const notificationCount = 2;

  return (
    <Stack
      screenOptions={{
        headerShadowVisible: false,
        headerTitle: "",

        /* LEFT: LOGO */
        headerLeft: () => (
          <Text style={styles.logo}>SARAN</Text>
        ),

        /* RIGHT: NOTIFICATION + MENU */
        headerRight: () => (
          <View style={styles.right}>
            <TouchableOpacity
              style={styles.iconWrap}
              onPress={() => router.push("/notifications")}
            >
              <FontAwesome6 name="bell" size={18} color="#000" />
              {notificationCount > 0 && (
                <View style={styles.badge}>
                  <Text style={styles.badgeText}>
                    {notificationCount}
                  </Text>
                </View>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              onPress={() => router.push("/profile/menu")}
            >
              <Ionicons name="menu" size={26} color="#000" />
            </TouchableOpacity>
          </View>
        ),
      }}
    >
      {/* ✅ REGISTER SCREENS EXPLICITLY */}
      <Stack.Screen name="index" />
      <Stack.Screen name="individual" />
      <Stack.Screen name="feed" />
    </Stack>
  );
}

/* ---------------- STYLES ---------------- */

const styles = StyleSheet.create({
  logo: {
    fontSize: 20,
    fontWeight: "700",
    color: "#000",
    marginLeft: 16,
  },

  right: {
    flexDirection: "row",
    alignItems: "center",
    gap: 18,
    marginRight: 16,
  },

  iconWrap: {
    position: "relative",
  },

  badge: {
    position: "absolute",
    top: -6,
    right: -8,
    backgroundColor: "#000",
    borderRadius: 8,
    minWidth: 16,
    height: 16,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 3,
  },

  badgeText: {
    fontSize: 10,
    color: "#fff",
    fontWeight: "600",
  },
});
