import { View, Text, Pressable, StyleSheet } from "react-native";

export default function MyEventsTabs({
  active,
  onChange,
}: {
  active: "Hosted" | "Booked";
  onChange: (v: "Hosted" | "Booked") => void;
}) {
  return (
    <View style={styles.container}>
      {["Hosted", "Booked"].map((tab) => (
        <Pressable
          key={tab}
          onPress={() => onChange(tab as any)}
          style={[
            styles.tab,
            active === tab && styles.activeTab,
          ]}
        >
          <Text>{tab}</Text>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    padding: 16,
  },
  tab: {
    flex: 1,
    padding: 10,
    alignItems: "center",
    borderRadius: 10,
  },
  activeTab: {
    backgroundColor: "#F2F2F2",
  },
});
