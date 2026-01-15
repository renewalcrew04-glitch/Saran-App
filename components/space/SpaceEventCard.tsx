import { View, Text, Image, StyleSheet, Pressable } from "react-native";
import { router } from "expo-router";
import CoverPlaceholder from "@/components/ui/CoverPlaceholder";
import profile from "@/app/(tabs)/profile";
export default function SpaceEventCard() {
  return (
    <Pressable
      onPress={() => router.push("/space/1")}
      style={styles.card}
    >

      <View style={styles.body}>
        <Text style={styles.title}>FareWell</Text>
        <Text style={styles.meta}>Fri, Dec 26 • 14:00</Text>
        <Text style={styles.meta}>Grand Auditorium, SSN College</Text>

        <View style={styles.row}>
          <Text style={styles.small}>0 joining</Text>
          <Text style={styles.small}>100 spots left</Text>
        </View>

        <Text style={styles.price}>₹100 per spot</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    margin: 16,
    borderRadius: 16,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "#EEE",
  },
  cover: {
    height: 160,
    width: "100%",
  },
  body: {
    padding: 12,
  },
  title: {
    fontSize: 16,
    fontWeight: "600",
  },
  meta: {
    fontSize: 12,
    color: "#666",
    marginTop: 4,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 8,
  },
  small: {
    fontSize: 12,
    color: "#666",
  },
  price: {
    marginTop: 8,
    fontSize: 14,
    fontWeight: "600",
  },
});
