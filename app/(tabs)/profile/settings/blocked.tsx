import { View, Text, StyleSheet } from "react-native";

export default function BlockedAccounts() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Blocked Accounts</Text>

      <Text style={styles.message}>
        Blocking tools are being improved to offer better control and safety.
      </Text>

      <Text style={styles.sub}>
        This feature will be available soon.
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
