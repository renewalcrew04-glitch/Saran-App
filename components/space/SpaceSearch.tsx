import { View, TextInput, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";

export default function SpaceSearch() {
  return (
    <View style={styles.container}>
      <Ionicons name="search-outline" size={18} color="#999" />
      <TextInput
        placeholder="Search events..."
        placeholderTextColor="#999"
        style={styles.input}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    margin: 16,
    height: 44,
    paddingHorizontal: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#E5E5E5",
    flexDirection: "row",
    alignItems: "center",
  },
  input: {
    marginLeft: 8,
    flex: 1,
  },
});
