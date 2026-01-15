import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function WellnessHome() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.subtitle}>
        Your space for balance, growth, and care
      </Text>

      <Text style={styles.section}>MENTAL WELLBEING</Text>

      <Card
        icon="moon-outline"
        title="S-Mind Journal"
        desc="Safe space to reflect"
        onPress={() => router.push("/profile/wellness/mind-journal")}
      />

      <Card
        icon="leaf-outline"
        title="Calm Corner"
        desc="Micro-calming exercises"
        onPress={() => router.push("/profile/wellness/calm-corner")}
      />

      <Card
        icon="heart-outline"
        title="S-Cycle"
        desc="Period & wellness tracker"
        highlight
        onPress={() => router.push("/profile/wellness/s-cycle")}
      />

      <Card
        icon="water-outline"
        title="Hydration Tap"
        desc="Daily water tracker"
        onPress={() => router.push("/profile/wellness/hydration")}
      />
    </View>
  );
}

function Card({ icon, title, desc, onPress, highlight = false }: any) {
  return (
    <TouchableOpacity
      onPress={onPress}
      style={[styles.card, highlight && styles.highlight]}
    >
      <Ionicons name={icon} size={22} />
      <View>
        <Text style={styles.cardTitle}>{title}</Text>
        <Text style={styles.cardDesc}>{desc}</Text>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, backgroundColor: "#fff" },
  subtitle: { textAlign: "center", marginVertical: 20, color: "#555" },
  section: { fontSize: 12, color: "#888", marginTop: 30, marginBottom: 10 },
  card: {
    flexDirection: "row",
    alignItems: "center",
    gap: 16,
    padding: 18,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#eee",
    marginBottom: 12,
  },
  highlight: { borderColor: "#000", borderWidth: 2 },
  cardTitle: { fontSize: 15, fontWeight: "600" },
  cardDesc: { fontSize: 12, color: "#666", marginTop: 2 },
});
