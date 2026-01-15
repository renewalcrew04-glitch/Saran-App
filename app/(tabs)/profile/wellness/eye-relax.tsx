import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { useEffect, useState } from "react";
import { useRouter } from "expo-router";
import Animated, { FadeIn, FadeOut } from "react-native-reanimated";
import * as Haptics from "expo-haptics";
import { markWellnessCompleted } from "@/lib/wellnessStreak";

type Step = {
  text: string;
  duration: number;
};

const STEPS: Step[] = [
  { text: "Blink slowly 10 times", duration: 8 },
  { text: "Look at something far away", duration: 6 },
  { text: "Now focus on something near", duration: 6 },
  { text: "Close your eyes and rest", duration: 6 },
];

export default function EyeRelax() {
  const router = useRouter();
  const [stepIndex, setStepIndex] = useState(0);
  const [seconds, setSeconds] = useState(STEPS[0].duration);
  const [done, setDone] = useState(false);

  const step = STEPS[stepIndex];

  useEffect(() => {
    if (done) return;

    // 🔔 gentle haptic when step starts
    Haptics.selectionAsync();

    setSeconds(step.duration);

    const interval = setInterval(() => {
      setSeconds((prev) => {
        if (prev <= 1) {
          clearInterval(interval);

          // 🔔 step transition haptic
          Haptics.selectionAsync();

          if (stepIndex === STEPS.length - 1) {
  Haptics.notificationAsync(
    Haptics.NotificationFeedbackType.Success
  );
  markWellnessCompleted(); // ✅ STREAK LOGGED HERE
  setDone(true);
} else {
            setStepIndex((i) => i + 1);
          }

          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [stepIndex, done]);

  return (
    <View style={styles.container}>
      <TouchableOpacity onPress={() => router.back()}>
        <Text style={styles.back}>← Eye Relaxation</Text>
      </TouchableOpacity>

      {!done ? (
        <Animated.View
          key={stepIndex}
          entering={FadeIn}
          exiting={FadeOut}
          style={styles.center}
        >
          <View style={styles.eyeCircle}>
            <Text style={styles.timer}>{seconds}</Text>
          </View>

          <Text style={styles.prompt}>{step.text}</Text>
        </Animated.View>
      ) : (
        <Animated.View entering={FadeIn} style={styles.center}>
          <View style={styles.doneCircle}>
            <Text style={styles.check}>✓</Text>
          </View>

          <Text style={styles.doneTitle}>Eyes refreshed</Text>
          <Text style={styles.doneSub}>
            Thank you for taking care of your vision
          </Text>
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
  eyeCircle: {
    width: 140,
    height: 140,
    borderRadius: 70,
    borderWidth: 4,
    borderColor: "#000",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 30,
  },
  timer: {
    fontSize: 42,
    fontWeight: "300",
  },
  prompt: {
    fontSize: 16,
    fontWeight: "300",
    textAlign: "center",
    paddingHorizontal: 30,
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
    textAlign: "center",
    paddingHorizontal: 40,
  },
});
