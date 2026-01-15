import { View, Text, StyleSheet, Image, TouchableOpacity } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { Video, ResizeMode } from "expo-av";
import Screen from "@/components/Screen";
import { Colors } from "@/constants/colors";
import { FilterPreview } from "@/components/sframe/filters";
import { Timestamp } from "firebase/firestore";

export default function SFrameViewer() {
  const router = useRouter();
  const params = useLocalSearchParams();

  const {
    mediaType,
    mediaUrl,
    filter,
    mood,
    expiresAt,
    textContent,
  } = params as any;

  // ⏳ Auto-expire safety
  if (expiresAt) {
    const exp =
      expiresAt instanceof Timestamp
        ? expiresAt.toDate()
        : new Date(Number(expiresAt));

    if (Date.now() > exp.getTime()) {
      router.back();
      return null;
    }
  }

  return (
    <Screen>
  <View style={styles.root}>
      <TouchableOpacity style={styles.close} onPress={() => router.back()}>
        <Text style={styles.closeText}>✕</Text>
      </TouchableOpacity>

      {/* MEDIA */}
      {mediaType === "photo" && mediaUrl && (
        <FilterPreview
          uri={mediaUrl}
          filter={filter || "normal"}
          size={360}
        />
      )}

      {mediaType === "video" && mediaUrl && (
        <Video
          source={{ uri: mediaUrl }}
          style={styles.video}
          resizeMode={ResizeMode.COVER}
          shouldPlay
          isLooping
        />
      )}

      {/* TEXT ONLY */}
      {mediaType === "text" && (
        <View style={styles.textWrap}>
          <Text style={styles.text}>{textContent}</Text>
        </View>
      )}

      {/* MOOD */}
      {mood && <Text style={styles.mood}>{mood}</Text>}
      </View>
</Screen>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Colors.black,
    justifyContent: "center",
    alignItems: "center",
  },
  close: {
    position: "absolute",
    top: 40,
    right: 20,
    zIndex: 10,
  },
  closeText: {
    color: Colors.white,
    fontSize: 22,
  },
  video: {
    width: "100%",
    height: "100%",
  },
  textWrap: {
    padding: 32,
  },
  text: {
    color: Colors.white,
    fontSize: 26,
    textAlign: "center",
  },
  mood: {
    position: "absolute",
    bottom: 40,
    color: Colors.white,
    fontSize: 14,
    opacity: 0.8,
  },
});
