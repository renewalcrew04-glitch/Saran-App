import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { Audio } from "expo-av";
import { useEffect, useState } from "react";
import { FontAwesome5 } from "@expo/vector-icons";

const SOUNDS = [
  {
    id: "rain",
    label: "Rain",
    icon: "cloud-rain",
    file: require("../../../../assets/sound/rain.mp3"),
  },
  {
    id: "wind",
    label: "Wind",
    icon: "wind",
    file: require("../../../../assets/sound/wind.mp3"),
  },
  {
    id: "chimes",
    label: "Chimes",
    icon: "bell",
    file: require("../../../../assets/sound/chimes.mp3"),
  },
  {
    id: "ocean",
    label: "Ocean",
    icon: "water",
    file: require("../../../../assets/sound/ocean.mp3"),
  },
  {
    id: "hum",
    label: "Hum",
    icon: "music",
    file: require("../../../../assets/sound/hum.mp3"),
  },
];

export default function Soundboard() {
  const [sound, setSound] = useState<Audio.Sound | null>(null);
  const [active, setActive] = useState<string | null>(null);

  const play = async (id: string, file: any) => {
    if (sound) {
      await sound.unloadAsync();
      setSound(null);
      if (active === id) {
        setActive(null);
        return;
      }
    }

    const { sound: s } = await Audio.Sound.createAsync(file, {
      shouldPlay: true,
      isLooping: true,
      volume: 0.8,
    });

    setSound(s);
    setActive(id);
  };

  useEffect(() => {
    return () => {
      if (sound) sound.unloadAsync();
    };
  }, [sound]);

  return (
    <View style={styles.container}>
      <Text style={styles.header}>S-Zen Soundboard</Text>

      <View style={styles.grid}>
        {SOUNDS.map((s) => (
          <TouchableOpacity
            key={s.id}
            style={[
              styles.tile,
              active === s.id && styles.activeTile,
            ]}
            onPress={() => play(s.id, s.file)}
          >
            <FontAwesome5
              name={s.icon as any}
              size={22}
              color={active === s.id ? "#fff" : "#000"}
            />
            <Text
              style={[
                styles.label,
                active === s.id && styles.activeText,
              ]}
            >
              {s.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {active && (
        <Text style={styles.playing}>
          Playing {SOUNDS.find(s => s.id === active)?.label}
        </Text>
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
    gap: 14,
  },
  tile: {
    width: "30%",
    aspectRatio: 1,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: "#ddd",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
  },
  activeTile: {
    backgroundColor: "#000",
    borderColor: "#000",
  },
  label: {
    fontSize: 13,
  },
  activeText: {
    color: "#fff",
  },
  playing: {
    marginTop: 24,
    textAlign: "center",
    color: "#666",
    fontSize: 13,
  },
});
