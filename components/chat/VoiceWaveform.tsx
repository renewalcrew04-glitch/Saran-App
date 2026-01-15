import { View, TouchableOpacity, StyleSheet } from "react-native";
import { Audio } from "expo-av";
import { useEffect, useRef, useState } from "react";
import { Ionicons } from "@expo/vector-icons";

type Props = {
  uri: string;
  isOwn: boolean;
};

export default function VoiceWaveform({
  uri,
  isOwn,
}: Props) {
  const soundRef = useRef<Audio.Sound | null>(null);
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    return () => {
      soundRef.current?.unloadAsync();
    };
  }, []);

  const togglePlay = async () => {
    if (!soundRef.current) {
      const sound = new Audio.Sound();
      await sound.loadAsync({ uri });
      soundRef.current = sound;

      sound.setOnPlaybackStatusUpdate((status) => {
        if (!status.isLoaded) return;

        if (status.durationMillis) {
          setProgress(
            status.positionMillis /
              status.durationMillis
          );
        }

        if (status.didJustFinish) {
          setPlaying(false);
          setProgress(0);
        }
      });

      await sound.playAsync();
      setPlaying(true);
    } else {
      if (playing) {
        await soundRef.current.pauseAsync();
        setPlaying(false);
      } else {
        await soundRef.current.playAsync();
        setPlaying(true);
      }
    }
  };

  return (
    <TouchableOpacity
      onPress={togglePlay}
      style={[
        styles.container,
        isOwn ? styles.own : styles.other,
      ]}
    >
      <Ionicons
        name={playing ? "pause" : "play"}
        size={18}
        color={isOwn ? "#fff" : "#000"}
      />

      <View style={styles.wave}>
        <View
          style={[
            styles.progress,
            { width: `${progress * 100}%` },
            isOwn && styles.progressOwn,
          ]}
        />
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },

  own: {},

  other: {},

  wave: {
    width: 120,
    height: 4,
    backgroundColor: "#ccc",
    borderRadius: 2,
    overflow: "hidden",
  },

  progress: {
    height: "100%",
    backgroundColor: "#000",
  },

  progressOwn: {
    backgroundColor: "#fff",
  },
});
