import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  LayoutAnimation,
  Platform,
  UIManager,
} from "react-native";
import { useState } from "react";
import { FontAwesome6 } from "@expo/vector-icons";
import { Colors } from "@constants/colors";
import { Spacing } from "@constants/spacing";
import { Typography } from "@constants/typography";

if (Platform.OS === "android") {
  UIManager.setLayoutAnimationEnabledExperimental?.(true);
}

const QUOTES = [
  "She believed in herself even when the world doubted her.",
  "A woman’s strength is quiet, deep, and unstoppable.",
  "You are not too much. You are enough.",
  "Strong women don’t wait for permission.",
  "Confidence looks good on you.",
  "Your power begins the moment you stop apologizing.",
  "She stood tall, even when she felt small.",
  "You are braver than you think.",
  "Your voice matters. Use it.",
  "Strength grows every time you choose yourself.",
  "A woman who chooses herself changes everything.",
  "Freedom is a woman owning her choices.",
  "Independent doesn’t mean alone.",
  "She built her own wings.",
  "You don’t need saving — you need space.",
  "Be free enough to be yourself.",
  "Your life, your rules.",
  "Independence is self-respect in action.",
  "Walk your path unapologetically.",
  "You were never meant to shrink.",
  "She rises every time she falls.",
  "Courage looks like continuing.",
  "Healing is a brave act.",
  "Even broken wings remember how to fly.",
  "Pain shaped her, but didn’t define her.",
  "Resilience is her second name.",
  "Every scar tells a survival story.",
  "She turns wounds into wisdom.",
  "Falling is not failing.",
  "You are worthy without proving anything.",
  "Self-love is revolutionary.",
  "Know your value, then add tax.",
  "She stopped chasing validation.",
  "You don’t need approval to shine.",
  "Your worth isn’t negotiable.",
  "Being yourself is your superpower.",
  "Confidence is quiet, not loud.",
  "You are allowed to take up space.",
  "Loving yourself is powerful.",
  "Dream boldly. You belong there.",
  "Her ambition scares those who lack it.",
  "Women can be soft and unstoppable.",
  "Your dreams are valid.",
  "She dares greatly.",
  "Go after what sets your soul on fire.",
  "Success has many faces — yours is one.",
  "You are allowed to want more.",
  "Build the life you imagine.",
  "She creates her own future.",
  "Growth is not linear — and that’s okay.",
  "Healing takes time, not weakness.",
  "Rest is productive.",
  "Becoming yourself is a journey.",
  "She blooms at her own pace.",
  "You are allowed to pause.",
  "Growth feels uncomfortable before it feels right.",
  "Every day you heal a little more.",
  "Progress is still progress.",
  "Gentle with yourself, always.",
];

function getDailyQuote() {
  const today = new Date().toISOString().slice(0, 10);
  let hash = 0;
  for (let i = 0; i < today.length; i++) {
    hash = today.charCodeAt(i) + ((hash << 5) - hash);
  }
  return QUOTES[Math.abs(hash) % QUOTES.length];
}

export default function DailyQuoteCard() {
  const quote = getDailyQuote();
  const [expanded, setExpanded] = useState(false);
  const [saved, setSaved] = useState(false);

  const toggleExpand = () => {
    LayoutAnimation.configureNext(
      LayoutAnimation.Presets.easeInEaseOut
    );
    setExpanded((prev) => !prev);
  };

  return (
    <TouchableOpacity
      activeOpacity={0.9}
      onPress={toggleExpand}
      style={styles.card}
    >
      <Text style={styles.quote}>{quote}</Text>

      {expanded && (
        <View style={styles.actions}>
          <TouchableOpacity
            style={styles.actionItem}
            onPress={() => setSaved((p) => !p)}
          >
            <FontAwesome6
              name="bookmark"
              solid={saved}
              size={14}
              color={Colors.black}
            />
            <Text style={styles.actionText}>Save</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionItem}>
            <FontAwesome6
              name="share-nodes"
              size={14}
              color={Colors.black}
            />
            <Text style={styles.actionText}>Share</Text>
          </TouchableOpacity>
        </View>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    paddingVertical: 15,          // 🔥 reduced height
    paddingHorizontal: Spacing.lg,
    borderRadius: 21,            // 🔥 pill shape
    backgroundColor: Colors.white,
    borderWidth: 1.5,
    borderColor: Colors.black,
  },

  quote: {
    ...Typography.body,
    textAlign: "center",
    color: Colors.black,
    fontSize: 15,
  },

  actions: {
    flexDirection: "row",
    justifyContent: "center",
    marginTop: Spacing.sm,
    gap: Spacing.lg,
  },

  actionItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },

  actionText: {
    fontSize: 12,
    color: Colors.black,
    fontWeight: "500",
  },
});
