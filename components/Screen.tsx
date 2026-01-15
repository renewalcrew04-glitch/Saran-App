import { ReactNode } from "react";
import { SafeAreaView, StyleSheet, View } from "react-native";
import { Colors } from "../constants/colors";

export default function Screen({ children }: { children: ReactNode }) {
  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>{children}</View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: Colors.white,
  },
  container: {
    flex: 1,
    backgroundColor: Colors.white,
  },
});
