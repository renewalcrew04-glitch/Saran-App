import { View, TextInput, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";

export default function ExploreSearch() {
  return (
    <View style={styles.container}>
      <Ionicons name="search-outline" size={20} color="#666" />
      <TextInput
        placeholder="Search people, posts, videos"
        placeholderTextColor="#999"
        style={styles.input}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    alignItems: "center",
    marginHorizontal: 16,
    marginBottom: 12,
    paddingHorizontal: 12,
    height: 44,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#E5E5E5",
    backgroundColor: "#fff",
  },
  input: {
    flex: 1,
    marginLeft: 8,
    fontSize: 14,
    color: "#000",
  },
});
