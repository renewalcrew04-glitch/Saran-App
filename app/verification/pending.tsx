import { View, Text, StyleSheet } from "react-native";
import { useEffect } from "react";
import { useRouter } from "expo-router";
import { useProfileStore } from "@/store/profileStore";
import { auth } from "@/services/firebase";

export default function VerificationPending() {
  const router = useRouter();
  const { verified, startVerificationListener } = useProfileStore();

  // 🔐 Attach verification listener safely
  useEffect(() => {
    let unsubscribe: (() => void) | undefined;

    const waitForAuth = () => {
      const user = auth.currentUser;
      if (!user) return;

      unsubscribe = startVerificationListener(user.uid);
    };

    waitForAuth();

    return () => {
      unsubscribe?.();
    };
  }, []);

  // ✅ Move to home ONLY after admin approval
  useEffect(() => {
    if (verified === true) {
      router.replace("/(tabs)/home");
    }
  }, [verified]);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Verification Pending</Text>

      <Text style={styles.text}>
        Your account is being verified by our team.
        {"\n\n"}
        This usually takes up to 60 minutes.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#000",
    padding: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: "800",
    color: "#fff",
    marginBottom: 12,
  },
  text: {
    fontSize: 16,
    color: "#aaa",
    textAlign: "center",
    lineHeight: 24,
  },
});
