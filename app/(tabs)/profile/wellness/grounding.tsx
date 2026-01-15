import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { useEffect, useState } from "react";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import { markWellnessCompleted } from "@/lib/wellnessStreak";
import Animated, {
  FadeIn,
  FadeOut,
  SlideInRight,
  SlideOutLeft,
} from "react-native-reanimated";

type Step = {
  count: number;
  label: string;
  prompt: string;
};

const STEPS: Step[] = [
  { count: 5, label: "See", prompt: "Name 5 things you can see around you" },
  { count: 4, label: "Touch", prompt: "Name 4 things you can touch right now" },
  { count: 3, label: "Hear", prompt: "Name 3 things you can hear" },
  { count: 2, label: "Smell", prompt: "Name 2 things you can smell" },
  { count: 1, label: "Taste", prompt: "Name 1 thing you can taste" },
];

export default function Grounding() {
  const router = useRouter();
  const [stepIndex, setStepIndex] = useState(0);
  const [completed, setCompleted] = useState(false);

  const step = STEPS[stepIndex];

  const handleNext = async () => {
  await Haptics.selectionAsync();

  if (stepIndex === STEPS.length - 1) {
  await Haptics.notificationAsync(
    Haptics.NotificationFeedbackType.Success
  );
  markWellnessCompleted(); // ✅ STREAK LOGGED HERE
  setCompleted(true);
}
 else {
    setStepIndex((prev) => prev + 1);
  }
};

  return (
    <View style={styles.container}>
      <TouchableOpacity onPress={() => router.back()}>
        <Text style={styles.back}>← 5-4-3-2-1 Grounding</Text>
      </TouchableOpacity>

      {!completed ? (
        <Animated.View
          key={step.count}
          entering={SlideInRight}
          exiting={SlideOutLeft}
          style={styles.center}
        >
          <View style={styles.circle}>
            <Text style={styles.count}>{step.count}</Text>
          </View>

          <Text style={styles.label}>{step.label}</Text>
          <Text style={styles.prompt}>{step.prompt}</Text>

          <TouchableOpacity style={styles.button} onPress={handleNext}>
            <Text style={styles.buttonText}>Done</Text>
          </TouchableOpacity>
        </Animated.View>
      ) : (
        <Animated.View
          entering={FadeIn}
          exiting={FadeOut}
          style={styles.center}
        >
          <View style={styles.doneCircle}>
            <Text style={styles.check}>✓</Text>
          </View>

          <Text style={styles.doneTitle}>You are grounded</Text>
          <Text style={styles.doneSub}>You are here, in this moment</Text>
        </Animated.View>
      )}
    </View>
  );
}

/* -------------------- STYLES -------------------- */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    padding: 20,
  },
  back: {
    fontSize: 16,
    marginBottom: 40,
  },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  circle: {
    width: 120,
    height: 120,
    borderRadius: 60,
    borderWidth: 4,
    borderColor: "#000",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 24,
  },
  count: {
    fontSize: 48,
    fontWeight: "300",
  },
  label: {
    fontSize: 18,
    fontWeight: "500",
    marginBottom: 10,
  },
  prompt: {
    fontSize: 14,
    color: "#555",
    textAlign: "center",
    marginBottom: 30,
    paddingHorizontal: 24,
  },
  button: {
    backgroundColor: "#000",
    paddingHorizontal: 40,
    paddingVertical: 14,
    borderRadius: 30,
  },
  buttonText: {
    color: "#fff",
    fontSize: 15,
  },
  doneCircle: {
    width: 90,
    height: 90,
    borderRadius: 45,
    backgroundColor: "#000",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 24,
  },
  check: {
    color: "#fff",
    fontSize: 36,
  },
  doneTitle: {
    fontSize: 22,
    fontWeight: "300",
    marginBottom: 6,
  },
  doneSub: {
    fontSize: 13,
    color: "#666",
  },
});
