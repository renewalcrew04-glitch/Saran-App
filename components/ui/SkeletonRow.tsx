import { View, StyleSheet } from "react-native";

export default function SkeletonRow() {
  return (
    <View style={styles.row}>
      <View style={styles.avatar} />

      <View style={styles.text}>
        <View style={styles.lineShort} />
        <View style={styles.lineLong} />
      </View>

      <View style={styles.button} />
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    padding: 14,
    borderRadius: 16,
    backgroundColor: "#fff",
    marginBottom: 10,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#eee",
  },
  text: {
    flex: 1,
    marginLeft: 12,
  },
  lineShort: {
    width: "50%",
    height: 10,
    backgroundColor: "#eee",
    borderRadius: 6,
    marginBottom: 6,
  },
  lineLong: {
    width: "70%",
    height: 8,
    backgroundColor: "#eee",
    borderRadius: 6,
  },
  button: {
    width: 64,
    height: 28,
    borderRadius: 14,
    backgroundColor: "#eee",
  },
});
