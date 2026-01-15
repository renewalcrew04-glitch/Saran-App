import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from "react-native";
import { useState } from "react";
import { Colors } from "@constants/colors";
import { Spacing } from "@constants/spacing";

const CATEGORIES = [
  "For You",
  "Following",
  "Wellness",
  "Career",
  "Lifestyle",
  "Motherhood",
  "Relationships",
  "Creativity",
  "Travel",
  "Inspiration",
  "Beauty",
  "Fitness",
  "Food",
  "Fashion",
  "Education",
];

export default function CategoryChips() {
  const [active, setActive] = useState("For You");

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.container}
    >
      {CATEGORIES.map((category) => {
        const isActive = active === category;

        return (
          <TouchableOpacity
            key={category}
            onPress={() => setActive(category)}
            activeOpacity={0.8}
            style={[
              styles.chip,
              isActive ? styles.activeChip : styles.inactiveChip,
            ]}
          >
            <Text
              style={[
                styles.text,
                isActive ? styles.activeText : styles.inactiveText,
              ]}
            >
              {category}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: Spacing.md,
    paddingTop: Spacing.md,
    paddingBottom: Spacing.sm,
    gap: 8,
  },

  chip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
  },

  activeChip: {
    backgroundColor: Colors.black,
    borderColor: Colors.black,
  },

  inactiveChip: {
    backgroundColor: Colors.white,
    borderColor: Colors.black,
  },

  text: {
    fontSize: 13,
    fontWeight: "500",
  },

  activeText: {
    color: Colors.white,
  },

  inactiveText: {
    color: Colors.black,
  },
});
