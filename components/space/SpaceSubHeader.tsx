import { View, Text, Pressable, StyleSheet } from "react-native";
import { router } from "expo-router";

export default function SpaceSubHeader() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Space</Text>

      <Pressable
        style={styles.hostBtn}
        onPress={() => router.push("/space/create")}
      >
        <Text style={styles.hostText}>Host Event</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  title: {
    fontSize: 18,
    fontWeight: "600",
  },
  hostBtn: {
  backgroundColor: "#000",
  paddingHorizontal: 16,
  paddingVertical: 8,
  borderRadius: 24,
},
hostText: {
  color: "#fff",
  fontSize: 13,
  fontWeight: "500",
},
});
