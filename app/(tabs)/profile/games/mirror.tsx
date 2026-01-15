import { View, Text, StyleSheet } from "react-native";
import { CameraView, useCameraPermissions } from "expo-camera";
import { useMemo } from "react";

const PROMPTS = [
  "I am enough",
  "I am proud of myself",
  "I deserve peace",
];

export default function Mirror() {
  const [permission, requestPermission] = useCameraPermissions();

  const prompt = useMemo(
    () => PROMPTS[Math.floor(Math.random() * PROMPTS.length)],
    []
  );

  if (!permission?.granted) {
    requestPermission();
    return null;
  }

  return (
    <View style={{ flex: 1 }}>
      <View style={styles.promptBox}>
        <Text style={styles.prompt}>{prompt}</Text>
      </View>

      <CameraView style={{ flex: 1 }} facing="front" />
    </View>
  );
}

const styles = StyleSheet.create({
  promptBox: {
    padding: 16,
    backgroundColor: "#000",
  },
  prompt: {
    color: "#fff",
    textAlign: "center",
    fontSize: 14,
  },
});
