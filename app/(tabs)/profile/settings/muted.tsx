import { View, Text, StyleSheet } from "react-native";

export default function MutedAccounts() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Muted Accounts</Text>

      <Text style={styles.message}>
        We’re working on advanced muting options to give you more peace of mind.
      </Text>

      <Text style={styles.sub}>
        Coming soon.
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
    fontSize: 20,
    fontWeight: "600",
    textAlign: "center",
    marginBottom: 12,
  },
  message: {
    fontSize: 15,
    color: "#444",
    textAlign: "center",
    lineHeight: 22,
  },
  sub: {
    marginTop: 8,
    fontSize: 14,
    color: "#888",
    textAlign: "center",
  },
});
