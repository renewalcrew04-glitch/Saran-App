import { View, Image, Text, Pressable, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";

export default function SpaceHeader() {
  return (
    <View style={styles.container}>
      <Image
        source={require("../../assets/images/icon.png")}
        style={styles.logo}
      />

      <View style={styles.right}>
        <Ionicons name="notifications-outline" size={22} />
        <Pressable style={styles.hostBtn}>
          <Ionicons name="add" size={16} color="#fff" />
          <Text style={styles.hostText}>Host Event</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    height: 56,
    paddingHorizontal: 16,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  logo: {
    width: 120,
    height: 28,
    resizeMode: "contain",
  },
  right: {
    flexDirection: "row",
    alignItems: "center",
  },
  hostBtn: {
    marginLeft: 12,
    backgroundColor: "#000",
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 20,
    flexDirection: "row",
    alignItems: "center",
  },
  hostText: {
    color: "#fff",
    marginLeft: 6,
    fontSize: 13,
    fontWeight: "500",
  },
});
