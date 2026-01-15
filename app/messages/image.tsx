import { Image, TouchableOpacity } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";

export default function ImagePreview() {
  const { uri } = useLocalSearchParams<{ uri: string }>();
  const router = useRouter();

  return (
    <TouchableOpacity
      style={{ flex: 1, backgroundColor: "#000" }}
      onPress={() => router.back()}
    >
      <Image
        source={{ uri }}
        style={{ flex: 1, resizeMode: "contain" }}
      />
    </TouchableOpacity>
  );
}
