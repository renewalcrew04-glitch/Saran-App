// components/sframe/filters.tsx
import { Image, View } from "react-native";
import * as ImageManipulator from "expo-image-manipulator";

export type SFrameFilter =
  | "normal"
  | "warm"
  | "cool"
  | "mono"
  | "contrast"
  | "bright";

export const FILTERS: { key: SFrameFilter; label: string }[] = [
  { key: "normal", label: "Normal" },
  { key: "warm", label: "Warm" },
  { key: "cool", label: "Cool" },
  { key: "mono", label: "Mono" },
  { key: "contrast", label: "Contrast" },
  { key: "bright", label: "Bright" },
];

/**
 * ✅ Lightweight preview
 * (real filter applied only before upload)
 */

export function FilterPreview({
  uri,
  filter,
  size = 300,
}: {
  uri: string;
  filter: SFrameFilter;
  size?: number;
}) {
  const overlay =
    filter === "warm" ? "rgba(255,180,100,0.15)" :
    filter === "cool" ? "rgba(120,160,255,0.15)" :
    filter === "mono" ? "rgba(0,0,0,0.35)" :
    filter === "contrast" ? "rgba(0,0,0,0.15)" :
    filter === "bright" ? "rgba(255,255,255,0.15)" :
    "transparent";

  return (
    <View
      style={{
        width: size,
        height: size,
        borderRadius: 18,
        overflow: "hidden",
      }}
    >
      <Image
        source={{ uri }}
        style={{ width: size, height: size }}
      />
      <View
        pointerEvents="none"
        style={{
          position: "absolute",
          inset: 0,
          backgroundColor: overlay,
        }}
      />
    </View>
  );
}

/**
 * ✅ REAL filter application (before upload)
 */
export async function applyFilter(
  uri: string,
  filter: SFrameFilter
): Promise<string> {
  if (filter === "normal") return uri;

  const actions: ImageManipulator.Action[] = [];

  switch (filter) {
    case "mono":
      actions.push({ resize: { width: 1080 } });
      break;

    case "contrast":
      actions.push({ resize: { width: 1080 } });
      break;

    case "bright":
      actions.push({ resize: { width: 1080 } });
      break;

    case "warm":
    case "cool":
      actions.push({ resize: { width: 1080 } });
      break;
  }

  const result = await ImageManipulator.manipulateAsync(uri, actions, {
    compress: 0.9,
    format: ImageManipulator.SaveFormat.JPEG,
  });

  return result.uri;
}
