import { View, StyleSheet } from "react-native";

export default function FollowSkeleton() {
  return (
    <View style={styles.row}>
      <View style={styles.avatar} />
      <View style={styles.lines}>
        <View style={styles.line} />
        <View style={[styles.line, { width: "60%" }]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    padding: 14,
  },
  avatar: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: "#eee",
    marginRight: 12,
  },
  lines: {
    flex: 1,
    justifyContent: "center",
  },
  line: {
    height: 10,
    backgroundColor: "#eee",
    borderRadius: 6,
    marginBottom: 6,
    width: "80%",
  },
});
