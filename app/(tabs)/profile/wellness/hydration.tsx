import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { useState } from "react";
import { useRouter } from "expo-router";
import Svg, { Path, Rect, Defs, ClipPath } from "react-native-svg";
import Animated, {
  useAnimatedProps,
  withSpring,
} from "react-native-reanimated";

/* ---------------- CONSTANTS ---------------- */
const SVG_WIDTH = 160;
const SVG_HEIGHT = 280;
const WATER_MAX_HEIGHT = 220;
const WATER_BOTTOM_Y = 278;

/* Animated SVG Rect */
const AnimatedRect = Animated.createAnimatedComponent(Rect);

/* ---------------- SCREEN ---------------- */
export default function Hydration() {
  const router = useRouter();

  const [glasses, setGlasses] = useState(0);
  const [goal, setGoal] = useState(8);

  const percentage = Math.min(glasses / goal, 1);
  const waterHeight = WATER_MAX_HEIGHT * percentage;
  const waterY = WATER_BOTTOM_Y - waterHeight;

  const animatedProps = useAnimatedProps(() => ({
    height: withSpring(waterHeight, {
      stiffness: 300,
      damping: 20,
      mass: 0.8,
    }),
    y: withSpring(waterY, {
      stiffness: 300,
      damping: 20,
      mass: 0.8,
    }),
  }));

  const textWhite = percentage > 0.5;

  return (
    <View style={styles.container}>
      <Header title="Hydration Tap" />

      {/* Bottle */}
      <TouchableOpacity
        activeOpacity={0.9}
        onPress={() => glasses < goal && setGlasses(glasses + 1)}
      >
        <View style={styles.bottleWrap}>
          <Svg width={SVG_WIDTH} height={SVG_HEIGHT} viewBox="0 0 160 280">
            <Defs>
              {/* Inner bottle clip */}
              <ClipPath id="bottleClip">
                <Path d="M55 40 L55 20 L105 20 L105 40 L118 58 L118 258 C118 268 108 278 80 278 C52 278 42 268 42 258 L42 58 Z" />
              </ClipPath>
            </Defs>

            {/* Water */}
            <AnimatedRect
              x="42"
              width="76"
              fill="black"
              clipPath="url(#bottleClip)"
              rx="18"
              animatedProps={animatedProps}
            />

            {/* Bottle outline */}
            <Path
              d="M55 40 L55 20 L105 20 L105 40 L120 60 L120 260 C120 270 110 280 80 280 C50 280 40 270 40 260 L40 60 Z"
              stroke="black"
              strokeWidth="3"
              fill="none"
            />

            {/* Cap */}
            <Rect x="60" y="5" width="40" height="15" rx="4" fill="black" />
          </Svg>

          {/* Count */}
          <View style={styles.countOverlay}>
            <Text style={[styles.count, textWhite && styles.white]}>
              {glasses}
            </Text>
            <Text style={[styles.of, textWhite && styles.whiteSub]}>
              of {goal}
            </Text>
          </View>
        </View>
      </TouchableOpacity>

      <Text style={styles.tapText}>Tap the bottle to add water</Text>

      {/* Controls */}
      <View style={styles.controls}>
        <TouchableOpacity
          disabled={glasses === 0}
          onPress={() => setGlasses(Math.max(0, glasses - 1))}
          style={[styles.controlBtn, glasses === 0 && styles.disabled]}
        >
          <Text style={styles.controlText}>−</Text>
        </TouchableOpacity>

        <TouchableOpacity
          onPress={() => glasses < goal && setGlasses(glasses + 1)}
          style={[styles.controlBtn, styles.primary]}
        >
          <Text style={[styles.controlText, { color: "#fff" }]}>+</Text>
        </TouchableOpacity>
      </View>

      {/* Progress */}
      <View style={styles.progressCard}>
        <View style={styles.progressRow}>
          <Text>Today's Progress</Text>
          <Text>{Math.round(percentage * 100)}%</Text>
        </View>

        <View style={styles.progressBar}>
          <View
            style={[
              styles.progressFill,
              { width: `${percentage * 100}%` },
            ]}
          />
        </View>

        {glasses >= goal && (
          <Text style={styles.success}>
            🎉 Goal reached! Great job staying hydrated!
          </Text>
        )}
      </View>

      {/* Goal */}
      <View style={styles.goalCard}>
        <Text style={styles.goalTitle}>Daily Goal</Text>

        <View style={styles.goalControls}>
          <TouchableOpacity
            onPress={() => goal > 4 && setGoal(goal - 1)}
            style={styles.goalBtn}
          >
            <Text>−</Text>
          </TouchableOpacity>

          <Text style={styles.goalValue}>{goal}</Text>

          <TouchableOpacity
            onPress={() => goal < 15 && setGoal(goal + 1)}
            style={styles.goalBtn}
          >
            <Text>+</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.goalSub}>glasses per day</Text>
      </View>
    </View>
  );
}

/* ---------------- HEADER ---------------- */
function Header({ title }: { title: string }) {
  const router = useRouter();
  return (
    <TouchableOpacity onPress={() => router.back()}>
      <Text style={styles.back}>← {title}</Text>
    </TouchableOpacity>
  );
}

/* ---------------- STYLES ---------------- */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#fff",
    alignItems: "center",
  },
  back: {
    alignSelf: "flex-start",
    marginBottom: 20,
    fontSize: 16,
  },

  bottleWrap: {
    marginTop: 20,
    alignItems: "center",
  },

  countOverlay: {
    position: "absolute",
    top: 125,
    width: "100%",
    alignItems: "center",
  },
  count: {
    fontSize: 30,
    fontWeight: "300",
    color: "#000",
  },
  of: {
    fontSize: 12,
    color: "#666",
  },
  white: {
    color: "#fff",
  },
  whiteSub: {
    color: "#ddd",
  },

  tapText: {
    marginTop: 16,
    fontSize: 13,
    color: "#777",
  },

  controls: {
    flexDirection: "row",
    marginTop: 20,
    gap: 20,
  },
  controlBtn: {
    width: 52,
    height: 52,
    borderRadius: 26,
    borderWidth: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  primary: {
    backgroundColor: "#000",
  },
  disabled: {
    opacity: 0.3,
  },
  controlText: {
    fontSize: 22,
  },

  progressCard: {
    width: "100%",
    marginTop: 30,
    backgroundColor: "#f7f7f7",
    padding: 16,
    borderRadius: 16,
  },
  progressRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 10,
  },
  progressBar: {
    height: 6,
    backgroundColor: "#ddd",
    borderRadius: 3,
  },
  progressFill: {
    height: 6,
    backgroundColor: "#000",
    borderRadius: 3,
  },
  success: {
    marginTop: 10,
    fontSize: 13,
    color: "#555",
    textAlign: "center",
  },

  goalCard: {
    width: "100%",
    marginTop: 20,
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#eee",
    alignItems: "center",
  },
  goalTitle: {
    marginBottom: 12,
  },
  goalControls: {
    flexDirection: "row",
    alignItems: "center",
    gap: 20,
  },
  goalBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    borderWidth: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  goalValue: {
    fontSize: 24,
    fontWeight: "300",
  },
  goalSub: {
    marginTop: 6,
    fontSize: 11,
    color: "#666",
  },
});
