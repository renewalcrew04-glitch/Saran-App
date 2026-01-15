import { View, StyleSheet } from "react-native";
import { useState } from "react";

import AppHeader from "@/components/AppHeader";
import SpaceSubHeader from "@/components/space/SpaceSubHeader";
import SpaceSearch from "@/components/space/SpaceSearch";
import SpaceCategories from "@/components/space/SpaceCategories";
import SpaceEventList from "@/components/space/SpaceEventList";
import MyEventsFAB from "@/components/space/MyEventsFAB";
import { SpaceCategory } from "@/components/space/types";

export default function SpaceScreen() {
  const [category, setCategory] = useState<SpaceCategory>("All");

  return (
    <View style={styles.container}>
      {/* Main app header (same as Home & Explore) */}
      <AppHeader />

      {/* Space title + Host Event */}
      <SpaceSubHeader />

      {/* Search */}
      <SpaceSearch />

      {/* Categories */}
      <SpaceCategories value={category} onChange={setCategory} />

      {/* Events */}
      <SpaceEventList category={category} />

      {/* Floating CTA */}
      <MyEventsFAB />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
});
