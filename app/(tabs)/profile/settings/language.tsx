import { View, Text, StyleSheet } from "react-native";

export default function Language() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>Language support coming soon 🌍</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, backgroundColor: "#fff" },
  text: { color: "#666" },
});
