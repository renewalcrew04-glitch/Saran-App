import { View, Text, Image, StyleSheet } from "react-native";
import JoinButton from "@/components/space/JoinButton";
import CoverPlaceholder from "@components/ui/CoverPlaceholder";
export default function EventDetailsScreen() {
  return (
    <View style={styles.container}>
<CoverPlaceholder height={220} />
      <View style={styles.body}>
        <Text style={styles.title}>FareWell</Text>
        <Text style={styles.meta}>Fri, Dec 26 • 14:00</Text>
        <Text style={styles.meta}>
          Grand Auditorium, SSN College, Chennai
        </Text>

        <View style={styles.row}>
          <Text style={styles.small}>0 joining</Text>
          <Text style={styles.small}>100 spots left</Text>
        </View>

        <Text style={styles.price}>₹100 per spot</Text>
      </View>

      <JoinButton />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#fff" },
  cover: { height: 220, width: "100%" },
  body: { padding: 16 },
  title: { fontSize: 20, fontWeight: "600" },
  meta: { fontSize: 13, color: "#666", marginTop: 6 },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 12,
  },
  small: { fontSize: 12, color: "#666" },
  price: {
    marginTop: 16,
    fontSize: 16,
    fontWeight: "600",
  },
});
