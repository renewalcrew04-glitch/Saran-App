import { View, Text, StyleSheet, TouchableOpacity, Alert } from "react-native";
import { useRouter } from "expo-router";
import { logout } from "@/utils/logout";
import { FontAwesome6 } from "@expo/vector-icons";

export default function ProfileMenu() {
  const router = useRouter();

  const onLogout = () => {
    Alert.alert(
      "Log out",
      "Are you sure you want to log out?",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Log out",
          style: "destructive",
          onPress: async () => {
            await logout();
            router.replace("/(auth)/login");
          },
        },
      ]
    );
  };

  const Item = ({
  label,
  onPress,
  danger,
  showArrow,
}: {
  label: string;
  onPress: () => void;
  danger?: boolean;
  showArrow?: boolean;
}) => (
  <TouchableOpacity style={styles.item} onPress={onPress}>
    <Text style={[styles.text, danger && styles.danger]}>
      {label}
    </Text>

    {showArrow && (
      <FontAwesome6
        name="angle-right"
        size={18}
        color="#999"
      />
    )}
  </TouchableOpacity>
);

  return (
    <View style={styles.container}>
      <Item label="Settings" showArrow onPress={() => router.push("/profile/settings")} />
      <Item label="Saved" onPress={() => router.push("/profile/saved")} />
      <Item label="Your Activity" onPress={() => router.push("/profile/activity")} />
      <Item label="Report a problem" onPress={() => router.push("/profile/report")} />
      <Item label="Account Status" onPress={() => router.push("/profile/status")} />
      <Item label="Edit Profile" onPress={() => router.push("/profile/edit")} />
      <Item label="Switch to Creator" onPress={() => router.push("/profile/creatorswitch")} />

      <View style={styles.divider} />

      <Item label="Logout" onPress={onLogout} danger />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    paddingTop: 12,
  },
  item: {
  paddingVertical: 16,
  paddingHorizontal: 20,
  flexDirection: "row",
  alignItems: "center",
  justifyContent: "space-between",
},
  text: {
    fontSize: 16,
    color: "#000",
  },
  danger: {
    color: "red",
    fontWeight: "600",
  },
  divider: {
    height: 1,
    backgroundColor: "#eee",
    marginVertical: 8,
  },
});
