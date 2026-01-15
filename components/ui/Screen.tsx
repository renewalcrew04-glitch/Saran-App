import { View, StyleSheet } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

export default function Screen({ children }: { children: React.ReactNode }) {
  return (
    <SafeAreaView style={styles.safe} edges={["top", "left", "right"]}>
      <View style={styles.container}>{children}</View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: "#fff",
  },
  container: {
    flex: 1,
  },
});
