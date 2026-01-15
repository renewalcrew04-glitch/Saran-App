import { View, Text, StyleSheet } from "react-native";

export default function ProfileActivity() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Activity</Text>

      <Text style={styles.message}>
        Your profile activity is being securely tracked within SARAN’s
        analytics system.
      </Text>

      <Text style={styles.subMessage}>
        Our developers are working on bringing this feature to you soon.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    paddingHorizontal: 24,
    justifyContent: "center",
  },
  title: {
    fontSize: 22,
    fontWeight: "600",
    marginBottom: 12,
    textAlign: "center",
  },
  message: {
    fontSize: 15,
    color: "#444",
    textAlign: "center",
    lineHeight: 22,
  },
  subMessage: {
    marginTop: 8,
    fontSize: 14,
    color: "#888",
    textAlign: "center",
  },
});
