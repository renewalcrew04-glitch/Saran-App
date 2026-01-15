import { View, Text, StyleSheet, TouchableOpacity } from "react-native";
import { useGardenStore } from "@/store/gardenStore";
import { Plant } from "@/components/profile/games/Plant";

export default function Garden() {
  const { plants, plantSeed, water, getStage } = useGardenStore();

  return (
    <View style={styles.container}>
      <Text style={styles.header}>S-Garden</Text>

      <View style={styles.grid}>
        {plants.map((p) => (
          <View key={p.id} style={styles.cell}>
            <Plant stage={Number(getStage(p))} />
          </View>
        ))}

        {plants.length < 12 && (
          <TouchableOpacity style={styles.add} onPress={plantSeed}>
            <Text style={{ fontSize: 22 }}>＋</Text>
          </TouchableOpacity>
        )}
      </View>

      {plants.length > 0 && (
        <TouchableOpacity style={styles.water} onPress={water}>
          <Text style={{ color: "#fff" }}>Water Garden</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  header: { fontSize: 20, fontWeight: "600", marginBottom: 20 },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
  },
  cell: {
    width: "22%",
    aspectRatio: 1,
  },
  add: {
    width: "22%",
    aspectRatio: 1,
    borderWidth: 1,
    borderStyle: "dashed",
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
  },
  water: {
    marginTop: 24,
    height: 52,
    borderRadius: 30,
    backgroundColor: "#000",
    alignItems: "center",
    justifyContent: "center",
  },
});
