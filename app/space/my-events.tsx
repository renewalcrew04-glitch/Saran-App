import { View, StyleSheet } from "react-native";
import { useState } from "react";
import MyEventsTabs from "@/components/space/MyEventsTabs";
import MyEventsList from "@/components/space/MyEventsList";

export default function MyEventsScreen() {
  const [tab, setTab] = useState<"Hosted" | "Booked">("Booked");

  return (
    <View style={styles.container}>
      <MyEventsTabs active={tab} onChange={setTab} />
      <MyEventsList tab={tab} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#fff" },
});
