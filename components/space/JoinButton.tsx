import { Pressable, Text, StyleSheet } from "react-native";
import { useState } from "react";
import { useEventStore } from "./EventStore";

export default function JoinButton() {
  const [joined, setJoined] = useState(false);
  const { bookEvent } = useEventStore();

  const handleJoin = () => {
    setJoined(true);
    bookEvent({ id: "1", title: "FareWell" });
  };

  return (
    <Pressable
      style={[styles.button, joined && styles.joinedButton]}
      onPress={handleJoin}
    >
      <Text style={[styles.text, joined && styles.joinedText]}>
        {joined ? "Joined" : "Join Event"}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    margin: 16,
    padding: 16,
    borderRadius: 14,
    backgroundColor: "#000",
    alignItems: "center",
  },
  joinedButton: { backgroundColor: "#F2F2F2" },
  text: { color: "#fff", fontSize: 15, fontWeight: "600" },
  joinedText: { color: "#000" },
});
