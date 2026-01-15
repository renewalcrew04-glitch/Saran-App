import { Redirect } from "expo-router";
import { ActivityIndicator } from "react-native";
import { useEffect } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "@/services/firebase";
import { useAuthStore } from "@/store/authStore";
import { useProfileStore } from "@/store/profileStore";

export default function Index() {
  const user = useAuthStore((s) => s.user);
  const setUser = useAuthStore((s) => s.setUser);

  const hydrate = useProfileStore((s) => s.hydrate);
  const startVerificationListener = useProfileStore(
    (s) => s.startVerificationListener
  );

  const profileCompleted = useProfileStore((s) => s.profileCompleted);
  const verificationStep = useProfileStore((s) => s.verificationStep);
  const verified = useProfileStore((s) => s.verified);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (firebaseUser) => {
      setUser(firebaseUser ?? null);
    });

    return unsub;
  }, []);

  useEffect(() => {
    if (!user?.uid) return;

    hydrate(user.uid);
    startVerificationListener(user.uid);
  }, [user?.uid]);

  if (user === undefined) {
    return <ActivityIndicator style={{ flex: 1 }} />;
  }

  if (!user) {
    return <Redirect href="/(auth)/login" />;
  }

  if (!profileCompleted) {
    return <Redirect href="/profile/complete" />;
  }

  if (verificationStep === "terms") {
    return <Redirect href="/verification/terms" />;
  }

  if (!verified) {
    return <Redirect href="/verification/pending" />;
  }

  return <Redirect href="/(tabs)" />;
}
