import { View, Text, TouchableOpacity, StyleSheet, Animated } from "react-native";
import { useEffect, useRef, useState } from "react";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import { markWellnessCompleted } from "@/lib/wellnessStreak";

const TOTAL_SECONDS = 60;
const CYCLE_DURATION = 4000; // inhale / exhale

export default function Breathing() {
  const router = useRouter();

  const scale = useRef(new Animated.Value(1)).current;

  const [started, setStarted] = useState(false);
  const [secondsLeft, setSecondsLeft] = useState(TOTAL_SECONDS);
  const [phase, setPhase] = useState<"inhale" | "exhale">("inhale");
  const [done, setDone] = useState(false);

  // 🔁 Breathing animation loop
  useEffect(() => {
    if (!started || done) return;

    Animated.loop(
      Animated.sequence([
        Animated.timing(scale, {
          toValue: 1.5,
          duration: CYCLE_DURATION,
          useNativeDriver: true,
        }),
        Animated.timing(scale, {
          toValue: 1,
          duration: CYCLE_DURATION,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, [started, done]);

  // ⏱ Timer
  useEffect(() => {
    if (!started) return;

    const interval = setInterval(() => {
      setSecondsLeft((prev) => {
        if (prev <= 1) {
  clearInterval(interval);
  setDone(true);
  markWellnessCompleted(); // ✅ STREAK LOGGED HERE
  return 0;
}
        return prev - 1;
      });
    }, 1000);

    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

    return () => clearInterval(interval);
  }, [started]);

  // 🔄 Phase switch
  useEffect(() => {
  if (!started) return;

  const phaseInterval = setInterval(async () => {
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Soft);
    setPhase((p) => (p === "inhale" ? "exhale" : "inhale"));
  }, CYCLE_DURATION);

  return () => clearInterval(phaseInterval);
}, [started]);

  return (
    <View style={styles.container}>
      <TouchableOpacity onPress={() => router.back()}>
        <Text style={styles.back}>← 1-Minute Breathing</Text>
      </TouchableOpacity>

      {!started && !done && (
        <View style={styles.center}>
          <Text style={styles.helper}>
            Find a comfortable position and relax
          </Text>

          <TouchableOpacity
            style={styles.startBtn}
            onPress={() => setStarted(true)}
          >
            <Text style={styles.startText}>Begin</Text>
          </TouchableOpacity>
        </View>
      )}

      {started && !done && (
        <View style={styles.center}>
          <Animated.View
            style={[
              styles.circle,
              {
                transform: [{ scale }],
              },
            ]}
          >
            <Text style={styles.seconds}>{secondsLeft}</Text>
          </Animated.View>

          <Text style={styles.phase}>
            {phase === "inhale" ? "Inhale…" : "Exhale…"}
          </Text>
        </View>
      )}

      {done && (
        <View style={styles.center}>
          <View style={styles.doneCircle}>
            <Text style={styles.check}>✓</Text>
          </View>

          <Text style={styles.doneTitle}>Well done</Text>
          <Text style={styles.doneSub}>
            You took a moment for yourself
          </Text>
        </View>
      )}
    </View>
  );
}

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
  helper: {
    fontSize: 14,
    color: "#666",
    marginBottom: 30,
    textAlign: "center",
  },
  startBtn: {
    backgroundColor: "#000",
    paddingHorizontal: 36,
    paddingVertical: 14,
    borderRadius: 30,
  },
  startText: {
    color: "#fff",
    fontSize: 16,
  },
  circle: {
    width: 160,
    height: 160,
    borderRadius: 80,
    borderWidth: 4,
    borderColor: "#000",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 30,
  },
  seconds: {
    fontSize: 40,
    fontWeight: "300",
  },
  phase: {
    fontSize: 20,
    fontWeight: "300",
  },
  doneCircle: {
    width: 90,
    height: 90,
    borderRadius: 45,
    backgroundColor: "#000",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 20,
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
