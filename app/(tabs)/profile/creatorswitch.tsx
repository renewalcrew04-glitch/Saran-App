import { View, Text, StyleSheet } from "react-native";

export default function CreatorSwitch() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Creator Accounts</Text>
      <Text style={styles.subtitle}>
        Creator features are coming soon ✨
      </Text>

      <Text style={styles.desc}>
        We’re building tools for creators to host spaces,
        share exclusive content, and grow meaningful communities.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    padding: 24,
    justifyContent: "center",
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    textAlign: "center",
  },
  subtitle: {
    fontSize: 16,
    marginTop: 8,
    textAlign: "center",
    color: "#666",
  },
  desc: {
    marginTop: 16,
    fontSize: 14,
    color: "#777",
    textAlign: "center",
    lineHeight: 20,
  },
});
