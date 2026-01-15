import { View, Text, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";

export default function RepostHeader({ label }: { label: string }) {
  return (
    <View style={styles.row}>
      <Ionicons name="repeat" size={14} color="#666" />
      <Text style={styles.text}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginBottom: 6,
    marginLeft: 4,
  },
  text: {
    fontSize: 12,
    color: "#666",
    fontWeight: "600",
  },
});
