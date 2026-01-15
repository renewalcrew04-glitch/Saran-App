import { View, Text, StyleSheet } from "react-native";
import { useEventStore } from "./EventStore";

export default function MyEventsList({
  tab,
}: {
  tab: "Hosted" | "Booked";
}) {
  const { bookedEvents } = useEventStore();

  if (tab === "Booked") {
    if (bookedEvents.length === 0) {
      return (
        <View style={styles.center}>
          <Text>You haven&apos;t booked any events yet</Text>
        </View>
      );
    }

    return (
      <View style={styles.list}>
        {bookedEvents.map((e) => (
          <Text key={e.id} style={styles.item}>
            {e.title}
          </Text>
        ))}
      </View>
    );
  }

  return (
    <View style={styles.center}>
      <Text>You haven&apos;t hosted any events yet</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  list: {
    padding: 16,
  },
  item: {
    paddingVertical: 12,
    fontSize: 14,
    fontWeight: "500",
  },
});
