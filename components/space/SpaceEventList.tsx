import { FlatList, Text } from "react-native";
import SpaceEventCard from "./SpaceEventCard";
import { SpaceCategory } from "./types";

export default function SpaceEventList({
  category,
}: {
  category: SpaceCategory;
}) {
  return (
    <FlatList
      data={[1]}
      keyExtractor={(i) => i.toString()}
      ListHeaderComponent={
        <Text style={{ marginLeft: 16, color: "#666" }}>
          1 events to explore
        </Text>
      }
      renderItem={() => <SpaceEventCard />}
    />
  );
}
