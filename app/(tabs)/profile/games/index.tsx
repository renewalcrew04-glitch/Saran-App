import { View, Text, StyleSheet, TouchableOpacity } from "react-native";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

const GAMES = [
  {
    id: "garden",
    title: "S-Garden",
    desc: "Grow positivity gently",
    icon: "leaf-outline",
  },
  {
    id: "soundboard",
    title: "S-Zen Soundboard",
    desc: "Calming sounds for peace",
    icon: "musical-notes-outline",
  },
  {
    id: "mirror",
    title: "S-Mirror Challenge",
    desc: "Self-love reflection",
    icon: "sparkles-outline",
  },
];

export default function GamesHome() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.header}>S-Games</Text>

      {GAMES.map((g) => (
        <TouchableOpacity
          key={g.id}
          style={styles.card}
          onPress={() => router.push(`/profile/games/${g.id}`)}
        >
          <View style={styles.iconWrap}>
            <Ionicons name={g.icon as any} size={22} />
          </View>

          <View style={{ flex: 1 }}>
            <Text style={styles.title}>{g.title}</Text>
            <Text style={styles.desc}>{g.desc}</Text>
          </View>
        </TouchableOpacity>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  header: {
    fontSize: 22,
    fontWeight: "600",
    marginBottom: 20,
  },
  card: {
    flexDirection: "row",
    gap: 14,
    padding: 16,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: "#eee",
    marginBottom: 14,
  },
  iconWrap: {
    width: 48,
    height: 48,
    borderRadius: 14,
    backgroundColor: "#f5f5f5",
    alignItems: "center",
    justifyContent: "center",
  },
  title: { fontSize: 16, fontWeight: "600" },
  desc: { fontSize: 13, color: "#666", marginTop: 2 },
});
