import { View, Text, StyleSheet } from "react-native";
import { useEffect, useState } from "react";
import { getWellnessStreak } from "@/lib/wellnessStreak";

export default function WellnessStreakCard() {
  const [streak, setStreak] = useState<number | null>(null);

  useEffect(() => {
    getWellnessStreak().then((data) => {
      setStreak(data?.current ?? 0);
    });
  }, []);

  return (
    <View style={styles.card}>
      <Text style={styles.count}>{streak}</Text>
      <Text style={styles.label}>day wellness streak</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    margin: 20,
    padding: 20,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: "#eee",
    alignItems: "center",
  },
  count: {
    fontSize: 42,
    fontWeight: "300",
  },
  label: {
    fontSize: 12,
    color: "#666",
    marginTop: 4,
  },
});
