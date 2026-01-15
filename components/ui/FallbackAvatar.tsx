import { View, Image, Text, StyleSheet } from "react-native";

export default function FallbackAvatar({
  uri,
  size = 40,
}: {
  uri?: string;
  size?: number;
}) {
  if (uri) {
    return (
      <Image
        source={{ uri }}
        style={{
          width: size,
          height: size,
          borderRadius: size / 2,
        }}
      />
    );
  }

  return (
    <View
      style={[
        styles.fallback,
        {
          width: size,
          height: size,
          borderRadius: size / 2,
        },
      ]}
    >
      <Text style={styles.text}>S</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  fallback: {
    backgroundColor: "#000",
    alignItems: "center",
    justifyContent: "center",
  },
  text: {
    color: "#fff",
    fontWeight: "600",
  },
});
