import { Video, ResizeMode } from "expo-av";

export default function VideoPreview({ uri }: { uri: string }) {
  return (
    <Video
      source={{ uri }}
      style={{ width: "100%", height: 320, borderRadius: 16 }}
      resizeMode={ResizeMode.COVER}
      useNativeControls
      isLooping
      shouldPlay
    />
  );
}
