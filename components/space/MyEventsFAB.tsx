import { Pressable, Text, StyleSheet } from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function MyEventsFAB() {
  return (
    <Pressable
      style={styles.fab}
      onPress={() => router.push("/space/my-events")}
    >
      <Ionicons name="calendar-outline" size={18} color="#fff" />
      <Text style={styles.text}>My Events & Booking</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fab: {
  position: "relative",
  alignSelf: "center",
  bottom: 20, // sits above bottom tab bar
  flexDirection: "row",
  alignItems: "center",
  backgroundColor: "#000",
  paddingHorizontal: 18,
  paddingVertical: 12,
  borderRadius: 28,
},
  text: {
    color: "#fff",
    marginLeft: 8,
    fontSize: 13,
    fontWeight: "500",
  },
});
