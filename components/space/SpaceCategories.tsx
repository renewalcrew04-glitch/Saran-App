import { ScrollView, Pressable, Text, StyleSheet } from "react-native";
import { SpaceCategory } from "./types";

const categories: SpaceCategory[] = [
  "All",
  "Workshop",
  "Meetup",
  "Fitness",
  "Art",
  "Wellness",
  "Food",
  "Travel",
  "Learning",
  "Social",
];

export default function SpaceCategories({
  value,
  onChange,
}: {
  value: SpaceCategory;
  onChange: (v: SpaceCategory) => void;
}) {
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.row}>
      {categories.map((cat) => (
        <Pressable
          key={cat}
          onPress={() => onChange(cat)}
          style={[
            styles.chip,
            value === cat && styles.activeChip,
          ]}
        >
          <Text
            style={[
              styles.text,
              value === cat && styles.activeText,
            ]}
          >
            {cat}
          </Text>
        </Pressable>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  row: {
    paddingHorizontal: 16,
  },
  chip: {
  height: 36,
  paddingHorizontal: 16,
  borderRadius: 18,
  borderWidth: 1,
  borderColor: "#E5E5E5",
  marginRight: 8,
  justifyContent: "center",
},
activeChip: {
  backgroundColor: "#000",
  borderColor: "#000",
},
  text: {
  fontSize: 13,
  color: "#666",
  fontWeight: "500",
},
activeText: {
  color: "#fff",
},
});
