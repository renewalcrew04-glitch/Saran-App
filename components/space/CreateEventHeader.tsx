import { View, Text, Pressable, StyleSheet } from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function CreateEventHeader() {
  return (
    <View style={styles.container}>
      <Pressable onPress={() => router.back()}>
        <Ionicons name="arrow-back" size={22} />
      </Pressable>

      <Text style={styles.title}>Create Event</Text>

      <View style={{ width: 22 }} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    height: 56,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderColor: "#EEE",
  },
  title: {
    fontSize: 16,
    fontWeight: "600",
  },
});
