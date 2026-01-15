import { View, Image, Pressable, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";

export default function ExploreHeader() {
  return (
    <View style={styles.container}>
      <Image
        source={require("../../assets/images/icon.png")}
        style={styles.logo}
      />

      <View style={styles.actions}>
        <Pressable>
          <Ionicons name="notifications-outline" size={22} color="#000" />
        </Pressable>
        <Pressable style={{ marginLeft: 16 }}>
          <Ionicons name="chatbubble-outline" size={22} color="#000" />
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
    alignItems: "center",
    justifyContent: "space-between",
  },
  logo: {
    height: 28,
    width: 120,
    resizeMode: "contain",
  },
  actions: {
    flexDirection: "row",
    alignItems: "center",
  },
});
