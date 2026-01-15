import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
} from "react-native";
import { useRouter } from "expo-router";
import { Colors } from "@constants/colors";
import { Spacing } from "@constants/spacing";
import { Typography } from "@constants/typography";

export default function ShareStoryCard() {
  const router = useRouter();

  return (
    <TouchableOpacity
      activeOpacity={0.9}
      onPress={() => router.push("/post/create")}
      style={styles.card}
    >
      {/* Gradient layers */}
      <View style={styles.gradientTop} />
      <View style={styles.gradientBottom} />

      {/* CONTENT (must be above gradient) */}
      <View style={styles.content}>
        <Text style={styles.placeholder}>
          What’s on your mind today?
        </Text>

        <View style={styles.plusWrap}>
          <Text style={styles.plus}>＋</Text>
        </View>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: Spacing.md,
    marginTop: Spacing.lg,
    borderRadius: 18,
    height: 58, // 🔥 fixed visibility
    backgroundColor: "#000",
    overflow: "hidden",
  },

  gradientTop: {
    position: "absolute",
    top: 0,
    height: "55%",
    width: "100%",
    backgroundColor: "#2a2a2a",
  },

  gradientBottom: {
    position: "absolute",
    bottom: 0,
    height: "45%",
    width: "100%",
    backgroundColor: "#000",
  },

  content: {
    flex: 1,
    paddingHorizontal: Spacing.lg,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },

  placeholder: {
    ...Typography.body,
    color: Colors.white,       // ✅ fully visible
    fontWeight: "500",
  },

  plusWrap: {
    width: 34,
    height: 34,
    borderRadius: 17,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.7)",
    alignItems: "center",
    justifyContent: "center",
  },

  plus: {
    fontSize: 20,
    color: Colors.white,
    marginTop: -1,
  },
});
