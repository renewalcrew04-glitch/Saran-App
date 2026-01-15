import { View, Text, StyleSheet } from "react-native";

export default function SFrameSettings() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>
        Control who can view and reply to your S-frames.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, backgroundColor: "#fff" },
  text: { color: "#666" },
});
